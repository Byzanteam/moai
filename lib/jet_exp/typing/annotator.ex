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
        {Ast.update_meta(node, :type, type), context}

      {:ok, type, context} ->
        {Ast.update_meta(node, :type, type), context}

      {:error, errors} ->
        {Ast.update_meta(node, :errors, errors), context}

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
        infer_access_op(node, context)

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
        {:error, line: Ast.extract_meta!(node, :line), reason: :not_exists, id: name}
    end
  end

  defp infer_list(node) do
    case Ast.list_args(node) do
      [] ->
        {:error, line: Ast.extract_meta!(node, :line), reason: :required, value: []}

      [elem | rest] ->
        elem
        |> do_infer_list(rest)
        |> attach_error_line(node)
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
        :"[a]"
        |> type_slaps()
        |> attach_error_line(node)

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
    predicate = Ast.conditional_predicate(node)

    case extract_type(predicate) do
      {:ok, :bool} ->
        node
        |> Ast.conditional_consequent()
        |> do_infer_conditional(Ast.conditional_alternative(node))
        |> attach_error_line(node)

      {:ok, _type} ->
        :bool
        |> type_slaps()
        |> attach_error_line(node)

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
    call_id = Ast.call_id(node)
    fun_name = Ast.id_name(call_id)
    args = Ast.call_args(node)

    context
    |> Context.lookup_functions(fun_name, &select_fun(&1, args))
    |> Enum.map(fn symbol_info ->
      symbol_info
      |> SymbolInfo.extract(:type)
      |> elem(1)
    end)
    |> do_infer_call(fun_name, args)
    |> attach_error_line(call_id)
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
    |> attach_error_line(node)
  end

  defp infer_comp_op(node) do
    [left, right] = Ast.op_operands(node)

    with(
      {:ok, type} <- extract_type(left),
      :ok <- has_type?(right, type)
    ) do
      {:ok, :bool}
    else
      error ->
        attach_error_line(error, node)
    end
  end

  defp infer_access_op(node, context) do
    [source_expr, accessor] = Ast.op_operands(node)

    case extract_type_expand_alias(source_expr, context) do
      {:ok, %{} = type} ->
        type
        |> do_infer_access_op(Ast.id_name(accessor))
        |> attach_error_line(accessor)

      {:ok, _type} ->
        :%{}
        |> type_slaps()
        |> attach_error_line(node)

      error ->
        error
    end
  end

  defp do_infer_access_op(object_type, accessor_name)
       when is_map_key(object_type, accessor_name) do
    {:ok, Map.fetch!(object_type, accessor_name)}
  end

  defp do_infer_access_op(object_type, _accessor_name) do
    {:error, reason: :key_not_found, keys: Map.keys(object_type)}
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

  defp attach_error_line({:error, errors}, node) do
    {:error, Keyword.put_new_lazy(errors, :line, fn -> Ast.extract_meta!(node, :line) end)}
  end

  defp attach_error_line(result, _node), do: result

  @spec extract_type(Ast.t() | Ast.list_comp_node_binding()) ::
          {:ok, Types.t() | Types.alias()} | {:error, errors()}
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
        with(:error <- Ast.extract_meta(node, :type)) do
          {:error, Ast.extract_meta!(node, :errors)}
        end
    end
  end

  defp extract_type_expand_alias(node, context) do
    with({:ok, type_alias} when is_binary(type_alias) <- extract_type(node)) do
      {:ok, _type} = Context.lookup_type(context, type_alias)
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
