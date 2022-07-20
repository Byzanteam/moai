defmodule JetExp.Core.Interpreter do
  @moduledoc false

  alias JetExp.Parser.Ast
  alias JetExp.Core.Interpreter.Env

  @spec eval(Ast.t(), Env.t()) :: {:ok, Env.value()} | :error
  def eval(node, env) do
    cond do
      Ast.literal?(node) ->
        {:ok, node}

      Ast.id?(node) ->
        Env.lookup(env, Ast.id_name(node))

      Ast.list?(node) ->
        eval_list(node, env)

      Ast.conditional?(node) ->
        eval_conditional(node, env)

      Ast.call?(node) ->
        apply_fun(node, env)

      Ast.arith_op?(node) ->
        eval_arith(node, env)

      Ast.logic_op?(node) ->
        eval_logic(node, env)

      Ast.rel_op?(node) ->
        eval_rel(node, env)

      Ast.comp_op?(node) ->
        eval_comp(node, env)

      Ast.access_op?(node) ->
        eval_access(node, env)

      Ast.list_comp?(node) ->
        eval_list_comp(node, env)
    end
  end

  defp eval_list(node, env) do
    node |> Ast.list_args() |> eval_args(env)
  end

  defp eval_conditional(node, env) do
    case node |> Ast.conditional_predicate() |> eval(env) do
      {:ok, true} ->
        node |> Ast.conditional_consequent() |> eval(env)

      {:ok, false} ->
        eval_conditional_alternative(node, env)

      nil_or_error ->
        nil_or_error
    end
  end

  defp eval_conditional_alternative(node, env) do
    case Ast.conditional_alternative(node) do
      {:ok, alternative} ->
        eval(alternative, env)

      :error ->
        {:ok, nil}
    end
  end

  defp apply_fun(node, env) do
    with({:ok, fun} <- Env.lookup(env, node |> Ast.call_id() |> Ast.id_name())) do
      do_apply_fun(fun, Ast.call_args(node), env)
    end
  end

  defp do_apply_fun(fun, [], _env) do
    Env.Function.apply(fun, [])
  end

  defp do_apply_fun(fun, args, env) do
    with({:ok, [_ | _] = args} <- eval_fun_args(fun, args, env)) do
      Env.Function.apply(fun, args)
    end
  end

  defp eval_fun_args(fun, args, env) do
    if Env.Function.require_args?(fun) do
      eval_required_args(args, env)
    else
      eval_args(args, env)
    end
  end

  defp eval_arith(node, env) do
    dispatch_op(node, env, &do_eval_arith/3)
  end

  defp do_eval_arith(:+, operands, env) do
    eval_binary_op(operands, env, &(&1 + &2))
  end

  defp do_eval_arith(:-, operands, env) do
    case eval_required_args(operands, env) do
      {:ok, [left, right]} ->
        {:ok, left - right}

      {:ok, [operand]} ->
        {:ok, -operand}

      result ->
        result
    end
  end

  defp do_eval_arith(:*, operands, env) do
    eval_binary_op(operands, env, &(&1 * &2))
  end

  defp do_eval_arith(:/, operands, env) do
    case eval_required_args(operands, env) do
      {:ok, [_left, 0]} ->
        {:ok, nil}

      {:ok, [left, right]} ->
        {:ok, left / right}

      result ->
        result
    end
  end

  defp eval_logic(node, env) do
    dispatch_op(node, env, &do_eval_logic/3)
  end

  defp do_eval_logic(:and, operands, env) do
    [left, right] = operands

    with({:ok, true} <- eval(left, env)) do
      eval(right, env)
    end
  end

  defp do_eval_logic(:or, operands, env) do
    [left, right] = operands

    with({:ok, false} <- eval(left, env)) do
      eval(right, env)
    end
  end

  defp do_eval_logic(:not, [operand], env) do
    with({:ok, value} when not is_nil(value) <- eval(operand, env)) do
      {:ok, not value}
    end
  end

  defp eval_rel(node, env) do
    rel_fun =
      case Ast.op_operator(node) do
        :> -> &(&1 > &2)
        :< -> &(&1 < &2)
        :>= -> &(&1 >= &2)
        :<= -> &(&1 <= &2)
      end

    eval_binary_op(
      Ast.op_operands(node),
      env,
      rel_fun
    )
  end

  defp eval_comp(node, env) do
    comp_fun =
      case Ast.op_operator(node) do
        :== -> &(&1 === &2)
        :!= -> &(&1 !== &2)
      end

    eval_binary_op(
      Ast.op_operands(node),
      env,
      comp_fun
    )
  end

  defp dispatch_op(node, env, fun) do
    fun.(
      Ast.op_operator(node),
      Ast.op_operands(node),
      env
    )
  end

  defp eval_binary_op(operands, env, fun) do
    with({:ok, [left, right]} <- eval_required_args(operands, env)) do
      {:ok, fun.(left, right)}
    end
  end

  defp eval_access(node, env) do
    [source, accessor] = Ast.op_operands(node)
    accessor_name = Ast.id_name(accessor)

    case eval(source, env) do
      {:ok, %{} = source_value} when is_map_key(source_value, accessor_name) ->
        {:ok, Map.fetch!(source_value, accessor_name)}

      _result ->
        :error
    end
  end

  defp eval_list_comp(node, env) do
    [var, source] = node |> Ast.list_comp_binding() |> Ast.list_comp_binding_args()

    with(
      {:ok, [_ | _] = source_value} <- eval(source, env),
      target = Ast.list_comp_target(node),
      [_ | _] = target_value <- do_eval_list_comp(source_value, target, var, env)
    ) do
      {:ok, Enum.reverse(target_value)}
    end
  end

  defp do_eval_list_comp(source_value, target, var, env) do
    var_name = Ast.id_name(var)

    Enum.reduce_while(source_value, [], fn v, acc ->
      env = Env.new(%{var_name => v}, env)

      case eval(target, env) do
        {:ok, value} ->
          {:cont, [value | acc]}

        :error ->
          {:halt, :error}
      end
    end)
  end

  @spec eval_args([Ast.t()], Env.t()) :: {:ok, [Ast.t()]} | :error
  defp eval_args(nodes, env) do
    with(value when is_list(value) <- do_eval_args(nodes, env)) do
      {:ok, Enum.reverse(value)}
    end
  end

  defp do_eval_args(nodes, env) do
    Enum.reduce_while(nodes, [], fn node, acc ->
      case eval(node, env) do
        {:ok, value} ->
          {:cont, [value | acc]}

        :error ->
          {:halt, :error}
      end
    end)
  end

  @spec eval_required_args([Ast.t()], Env.t()) :: {:ok, [Ast.t()]} | {:ok, nil} | :error
  defp eval_required_args(nodes, env) do
    case eval_list_while(nodes, &(not is_nil(&1)), env) do
      {:ok, args} ->
        {:ok, args}

      :halted ->
        {:ok, nil}

      error ->
        error
    end
  end

  def eval_list_while(nodes, predicate, env) do
    with({:ok, value} <- do_eval_list_while(nodes, predicate, env, [])) do
      {:ok, Enum.reverse(value)}
    end
  end

  defp do_eval_list_while([], _predicate, _env, acc) do
    {:ok, acc}
  end

  defp do_eval_list_while([node | rest], predicate, env, acc) do
    with(
      {:ok, value} <- eval(node, env),
      true <- predicate.(value)
    ) do
      do_eval_list_while(rest, predicate, env, [value | acc])
    else
      false -> :halted
      error -> error
    end
  end
end
