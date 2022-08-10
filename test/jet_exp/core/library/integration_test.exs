defmodule JetExp.Core.Library.IntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  alias JetExp.Parser.Ast

  alias JetExp.Parser.Context
  alias JetExp.Core.Interpreter.Env

  alias JetExp.Core.Library

  @libs [
    Library.Kernel,
    Library.Number,
    Library.String,
    Library.Bool,
    Library.Array
  ]

  setup do
    context =
      []
      |> Context.new()
      |> Context.install_type_aliases(%{
        "date_time" => %{
          "year" => :number,
          "month" => :number,
          "day" => :number,
          "hour" => :number,
          "minute" => :number,
          "second" => :number
        }
      })
      |> then(
        &Enum.reduce(@libs, &1, fn lib, context -> apply(lib, :install_symbols, [context]) end)
      )

    env =
      []
      |> Env.new()
      |> then(
        &Enum.reduce(@libs, &1, fn lib, context -> apply(lib, :install_bindings, [context]) end)
      )

    [context: context, env: env]
  end

  test "works", %{context: context, env: env} do
    assert_type_and_value(
      """
      Bool.and_a(
      for x in xs ->
        String.contains?(x, "foo")
      )
      """,
      context,
      env,
      [xs: {[:string], ["foo", "foobar", "bar"]}],
      :bool,
      false
    )

    assert_type_and_value(
      """
      if(
        Array.contains?(xs, nil),
        0,
        Number.sum_a(xs)
      )
      """,
      context,
      env,
      [xs: {[:number], [1, 2, 3]}],
      :number,
      6
    )

    assert_type_and_value(
      """
      String.contains?(xs, x)
      """,
      context,
      env,
      [xs: {:string, "foobar"}, x: {:string, nil}],
      :bool,
      nil
    )

    assert_type_and_value(
      """
      if(
      Bool.and_a(for n in ns -> n > 10),
      "good",
      "bad"
      )
      """,
      context,
      env,
      [ns: {[:number], [10, 11, 12]}],
      :string,
      "bad"
    )

    assert_type_and_value(
      """
      String.join(
        for x in xs -> if(is_nil(x), "hello", x),
        ";"
      )
      """,
      context,
      env,
      [xs: {[:string], [nil, "foo", "bar"]}],
      :string,
      "hello;foo;bar"
    )
  end

  defp assert_type_and_value(code, context, env, vars, type, value) do
    assert {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    assert {:ok, ast} = JetExp.Parser.parse(tokens)

    context =
      Enum.reduce(vars, context, fn {name, {type, _value}}, acc ->
        Context.declare(acc, Atom.to_string(name), Context.SymbolInfo.new(%{type: type}))
      end)

    {aast, _acc} =
      Ast.traverse(
        ast,
        context,
        &JetExp.Core.Macro.expander/2,
        &JetExp.Typing.Annotator.annotator/2
      )

    assert {:ok, type} === Ast.extract_meta(aast, :type)
    assert :error === Ast.extract_meta(aast, :errors)

    bindings =
      Map.new(vars, fn {name, {_type, value}} ->
        {Atom.to_string(name), value}
      end)

    assert {:ok, value} ===
             JetExp.Core.Interpreter.eval(
               aast,
               Env.install_bindings(env, bindings)
             )
  end
end
