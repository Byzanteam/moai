defmodule JetExp.Parser.IntegrationTest do
  use ExUnit.Case

  @moduletag :integration

  alias JetExp.Parser.Context.SymbolInfo

  test "works" do
    date_t = %{"year" => :number, "month" => :number, "day" => :number}

    context =
      %{
        "ds" => SymbolInfo.new(%{type: [date_t]}),
        "date_diff_seconds" => SymbolInfo.new(%{type: {:fun, [date_t, date_t, :number]}})
      }
      |> JetExp.Parser.Context.new()
      |> JetExp.Core.Macro.Sigil.BuiltIn.install()

    code = """
    for d in ds -> date_diff_seconds(~d\"2020-01-01\", d)
    """

    assert {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    assert {:ok, ast} = JetExp.Parser.parse(tokens)

    {aast, _acc} =
      JetExp.Parser.Ast.traverse(
        ast,
        context,
        &JetExp.Core.Macro.expander/2,
        &JetExp.Typing.Annotator.annotator/2
      )

    assert aast ===
             {:for, [type: [:number]],
              [
                {:in, [type: date_t], [{:id, "d"}, {:id, [type: [date_t]], "ds"}]},
                {{:id, "date_diff_seconds"}, [type: :number],
                 [%{"year" => 2020, "month" => 1, "day" => 1}, {:id, [type: date_t], "d"}]}
              ]}

    code = """
    for d in ds -> date_diff_seconds(~d\"2020.01-01\", d)
    """

    assert {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    assert {:ok, ast} = JetExp.Parser.parse(tokens)

    {aast, _acc} =
      JetExp.Parser.Ast.traverse(
        ast,
        context,
        &JetExp.Core.Macro.expander/2,
        &JetExp.Typing.Annotator.annotator/2
      )

    assert aast ===
             {:for, [errors: [reason: :format]],
              [
                {:in, [type: date_t], [{:id, "d"}, {:id, [type: [date_t]], "ds"}]},
                {{:id, "date_diff_seconds"}, [errors: [reason: :format]],
                 [
                   {:sigil, [errors: [reason: :format]], ["d", "2020.01-01"]},
                   {:id, [type: date_t], "d"}
                 ]}
              ]}
  end
end
