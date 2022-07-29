defmodule JetExp.Typing.Annotator do
  @moduledoc false

  alias JetExp.Parser.Ast

  alias JetExp.Parser.Context
  alias JetExp.Parser.Context.SymbolInfo

  alias JetExp.Typing.Types

  @type errors() :: Keyword.t()

  @doc """
  `annotator/2` is a postwalker that infer types and collect
  type errors.
  """
  @spec annotator(Ast.t(), Context.t()) :: {Ast.t(), Context.t()}
  def annotator(node, context) do
    case infer(node, context) do
      {:ok, type} ->
        {Ast.annotate(node, type: type), context}

      {:ok, type, context} ->
        {Ast.annotate(node, type: type), context}

      {:error, errors} ->
        {Ast.annotate(node, errors: errors), context}

      :skip ->
        {node, context}
    end
  end

  defp infer(node, context) do
    cond do
      Ast.literal?(node) ->
        :skip

      Ast.id?(node) ->
        infer_id(node, context)

      Ast.list?(node) ->
        infer_list(node)

      Ast.list_comp_binding?(node) ->
        perform_list_comp_binding(node, context)

      Ast.list_comp?(node) ->
        infer_list_comp(node, context)

      Ast.conditional?(node) ->
        infer_conditional(node)

      Ast.call?(node) ->
        infer_call(node, context)

      Ast.arith_op?(node) ->
        infer_op(node, :number, :number)

      Ast.logic_op?(node) ->
        infer_op(node, :bool, :bool)

      Ast.rel_op?(node) ->
        infer_op(node, :number, :bool)

      Ast.comp_op?(node) ->
        infer_comp_op(node)

      Ast.access_op?(node) ->
        infer_access_op(node)

      true ->
        :skip
    end
  end

  defp infer_id(node, context) do
    name = Ast.id_name(node)

    case Context.lookup_symbol(context, name) do
      {:ok, info} when not is_list(info) ->
        {:ok, SymbolInfo.extract(info, :type)}

      :error ->
        {:error, reason: :not_exists, id: name}
    end
  end

  defp infer_list(node) do
    case Ast.list_args(node) do
      [] ->
        {:error, reason: :required, value: []}

      [elem | rest] ->
        do_infer_list(elem, rest)
    end
  end

  defp do_infer_list(elem, rest) do
    with({:ok, type} <- extract_type(elem)) do
      check_homogeneous(rest, type, [type])
    end
  end

  defp perform_list_comp_binding(node, context) do
    [var, source_expr] = Ast.list_comp_binding_args(node)

    case extract_type(source_expr) do
      {:ok, [type]} ->
        context =
          Context.new(context, symbols: %{Ast.id_name(var) => SymbolInfo.new(%{type: type})})

        {:ok, type, context}

      {:ok, _type} ->
        type_slaps(:"[a]")

      error ->
        error
    end
  end

  defp infer_list_comp(node, context) do
    context = context.enclosing

    with(
      {:ok, _type} <- node |> Ast.list_comp_binding() |> extract_type(),
      {:ok, type} <- node |> Ast.list_comp_target() |> extract_type()
    ) do
      {:ok, [type], context}
    end
  end

  defp infer_conditional(node) do
    case node |> Ast.conditional_predicate() |> extract_type() do
      {:ok, :bool} ->
        do_infer_conditional(
          Ast.conditional_consequent(node),
          Ast.conditional_alternative(node)
        )

      {:ok, _type} ->
        type_slaps(:bool)

      error ->
        error
    end
  end

  defp do_infer_conditional(consequent, :error) do
    extract_type(consequent)
  end

  defp do_infer_conditional(consequent, {:ok, alternative}) do
    with(
      {:ok, type} <- extract_type(consequent),
      :ok <- has_type?(alternative, type)
    ) do
      {:ok, type}
    end
  end

  defp infer_call(node, context) do
    fun_name = node |> Ast.call_id() |> Ast.id_name()
    args = Ast.call_args(node)

    context
    |> Context.lookup_functions(fun_name, &select_fun(&1, args))
    |> Enum.map(fn symbol_info ->
      symbol_info
      |> SymbolInfo.extract(:type)
      |> elem(1)
    end)
    |> do_infer_call(fun_name, args)
  end

  defp select_fun(symbol_info, args) do
    args_count = length(args)

    case SymbolInfo.extract(symbol_info, :type) do
      {:fun, [_ | _] = arg_and_ret_types} when length(arg_and_ret_types) - 1 === args_count ->
        true

      _other ->
        false
    end
  end

  defp do_infer_call([], fun_name, _args) do
    {:error, reason: :not_exists, id: fun_name}
  end

  defp do_infer_call([[ret_type]], _fun_name, []) do
    {:ok, ret_type}
  end

  defp do_infer_call(_funs, fun_name, []) do
    {:error, reason: :not_exists, id: fun_name}
  end

  defp do_infer_call(funs, fun_name, [arg | args]) do
    with({:ok, arg_type} <- extract_type(arg)) do
      funs
      |> narrow_funs(arg_type)
      |> do_infer_call(fun_name, args)
    end
  end

  defp narrow_funs(funs, arg_type) do
    List.foldl(funs, [], fn
      [^arg_type | arg_and_ret_types], acc ->
        [arg_and_ret_types | acc]

      _fun_type, acc ->
        acc
    end)
  end

  defp infer_op(node, expected_type, final_type) do
    node
    |> Ast.op_operands()
    |> check_homogeneous(expected_type, final_type)
  end

  defp infer_comp_op(node) do
    [left, right] = Ast.op_operands(node)

    with(
      {:ok, type} <- extract_type(left),
      :ok <- has_type?(right, type)
    ) do
      {:ok, :bool}
    end
  end

  defp infer_access_op(node) do
    [source_expr, accessor] = Ast.op_operands(node)
    accessor_name = Ast.id_name(accessor)

    case extract_type(source_expr) do
      {:ok, %{} = type} when is_map_key(type, accessor_name) ->
        {:ok, Map.fetch!(type, accessor_name)}

      {:ok, %{} = type} ->
        {:error, reason: :key_not_found, keys: Map.keys(type)}

      {:ok, _type} ->
        type_slaps(:%{})

      error ->
        error
    end
  end

  defp has_type?(node, type) do
    case extract_type(node) do
      {:ok, ^type} ->
        :ok

      {:ok, _type} ->
        type_slaps(type)

      error ->
        error
    end
  end

  defp check_homogeneous(nodes, expected_type, final_type) do
    Enum.find_value(nodes, {:ok, final_type}, fn node ->
      with(:ok <- has_type?(node, expected_type)) do
        false
      end
    end)
  end

  def type_slaps(expected_type) do
    {:error, reason: :type_slaps, expected_type: expected_type}
  end

  @spec extract_type(Ast.t() | Ast.list_comp_node_binding()) ::
          {:ok, Types.t()} | {:error, errors()}
  def extract_type(node) do
    cond do
      Ast.nil?(node) ->
        {:ok, nil}

      Ast.bool?(node) ->
        {:ok, :bool}

      Ast.number?(node) ->
        {:ok, :number}

      Ast.string?(node) ->
        {:ok, :string}

      Ast.object?(node) ->
        extract_object_type(node)

      true ->
        with(:error <- Ast.extract_annotation(node, :type)) do
          {:ok, errors} = Ast.extract_annotation(node, :errors)
          {:error, errors}
        end
    end
  end

  defp extract_object_type(node) do
    Enum.reduce_while(node, {:ok, %{}}, fn {k, v}, {:ok, acc} ->
      case extract_type(v) do
        {:ok, type} ->
          {:cont, {:ok, Map.put(acc, k, type)}}

        error ->
          {:halt, error}
      end
    end)
  end
end
