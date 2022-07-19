defmodule JetExp.Typing.Annotator do
  @moduledoc false

  alias JetExp.Parser.Ast

  alias JetExp.SymbolTable
  alias JetExp.SymbolTable.SymbolInfo

  alias JetExp.Typing.Types

  @type errors() :: Keyword.t()

  @spec annotate(Ast.t(), SymbolTable.t()) :: Ast.t()
  def annotate(node, symbol_table) do
    {aast, _acc} =
      Ast.postwalk(node, symbol_table, fn n, acc ->
        case infer(n, acc) do
          {:ok, type} ->
            {Ast.annotate(n, type: type), acc}

          {:ok, type, acc} ->
            {Ast.annotate(n, type: type), acc}

          {:error, errors} ->
            {Ast.annotate(n, errors: errors), acc}

          :skip ->
            {n, acc}
        end
      end)

    aast
  end

  defp infer(node, symbol_table) do
    cond do
      Ast.nil?(node) ->
        :skip

      Ast.bool?(node) ->
        :skip

      Ast.number?(node) ->
        :skip

      Ast.string?(node) ->
        :skip

      Ast.id?(node) ->
        infer_id(node, symbol_table)

      Ast.list?(node) ->
        infer_list(node)

      Ast.list_comp_binding?(node) ->
        perform_list_comp_binding(node, symbol_table)

      Ast.list_comp?(node) ->
        infer_list_comp(node, symbol_table)

      Ast.conditional?(node) ->
        infer_conditional(node)

      Ast.call?(node) ->
        infer_call(node, symbol_table)

      Ast.arith_op?(node) ->
        infer_op(node, :number, :number)

      Ast.logic_op?(node) ->
        infer_op(node, :bool, :bool)

      Ast.rel_op?(node) ->
        infer_op(node, :number, :bool)

      Ast.comp_op?(node) ->
        infer_comp_op(node)
    end
  end

  defp infer_id(node, symbol_table) do
    name = Ast.id_name(node)

    case SymbolTable.lookup(symbol_table, name) do
      {:ok, info} ->
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

  defp perform_list_comp_binding(node, symbol_table) do
    [var, source_expr] = Ast.list_comp_binding_args(node)

    case extract_type(source_expr) do
      {:ok, [type]} ->
        symbol_table =
          SymbolTable.new(%{Ast.id_name(var) => SymbolInfo.new(%{type: type})}, symbol_table)

        {:ok, type, symbol_table}

      {:ok, _type} ->
        type_slaps(:"[a]")

      error ->
        error
    end
  end

  defp infer_list_comp(node, symbol_table) do
    symbol_table = symbol_table.surrounding

    with(
      {:ok, _type} <- node |> Ast.list_comp_binding() |> extract_type(),
      {:ok, type} <- node |> Ast.list_comp_target() |> extract_type()
    ) do
      {:ok, [type], symbol_table}
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

  defp infer_call(node, symbol_table) do
    case node |> Ast.call_id() |> infer_id(symbol_table) do
      {:ok, {:fun, _type} = fun_type} ->
        do_infer_call(fun_type, Ast.call_args(node))

      {:ok, _type} ->
        type_slaps(:fun)

      error ->
        error
    end
  end

  defp do_infer_call({:fun, [_ | _] = arg_and_ret_types}, args) do
    expected_args_count = length(arg_and_ret_types) - 1

    if expected_args_count === length(args) do
      do_infer_call(arg_and_ret_types, args)
    else
      {:error, reason: :arity, expected_arg_count: expected_args_count}
    end
  end

  defp do_infer_call({:fun, {arg_type, ret_type}}, args) do
    check_homogeneous(args, arg_type, ret_type)
  end

  defp do_infer_call([ret_type], []) do
    {:ok, ret_type}
  end

  defp do_infer_call([arg_type | arg_types], [arg | args]) do
    case extract_type(arg) do
      {:ok, ^arg_type} ->
        do_infer_call({:fun, arg_types}, args)

      {:ok, _type} ->
        type_slaps(arg_type)

      error ->
        error
    end
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

  defp has_type?(node, type) do
    case extract_type(node) do
      {:ok, ^type} ->
        :ok

      {:ok, _type} ->
        type_slaps(type)

      {:error, errors} ->
        {:error, errors}
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

      true ->
        with(:error <- Ast.extract_annotation(node, :type)) do
          {:ok, errors} = Ast.extract_annotation(node, :errors)
          {:error, errors}
        end
    end
  end
end
