defmodule JetExp.Core.Macro.SigilTest do
  use ExUnit.Case

  @moduletag :unit

  test "works" do
    assert %{
             "year" => 2020,
             "month" => 1,
             "day" => 20
           } === expand("~d\"2020-01-20\"")
  end

  test "fails" do
    assert {:ok, [reason: :format]} ===
             "~d\"2020.01/20\""
             |> expand()
             |> JetExp.Parser.Ast.extract_annotation(:errors)
  end

  defp expand(code) do
    {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    {:ok, ast} = JetExp.Parser.parse(tokens)
    context = [] |> JetExp.Parser.Context.new() |> JetExp.Core.Macro.Sigil.BuiltIn.install()
    {ast, _acc} = JetExp.Parser.Ast.prewalk(ast, context, &JetExp.Core.Macro.expander/2)
    ast
  end
end
