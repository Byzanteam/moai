defmodule Moai.Core.Macro.SigilTest do
  use ExUnit.Case

  @moduletag :unit

  test "works" do
    assert %{
             "year" => 2020,
             "month" => 1,
             "day" => 20,
             "hour" => 20,
             "minute" => 38,
             "second" => 50
           } === expand("~d\"2020-01-20 20:38:50\"")
  end

  test "fails" do
    assert {:ok, [reason: :format]} ===
             "~d\"2020-01.20T20:38:50\""
             |> expand()
             |> Moai.Parser.Ast.extract_meta(:errors)
  end

  defp expand(code) do
    {:ok, tokens} = Moai.Tokenizer.tokenize(code)
    {:ok, ast} = Moai.Parser.parse(tokens)
    context = [] |> Moai.Parser.Context.new() |> Moai.Core.Macro.Sigil.BuiltIn.install()
    {ast, _acc} = Moai.Parser.Ast.prewalk(ast, context, &Moai.Core.Macro.expander/2)
    ast
  end
end
