defmodule Moai.IntegrationTest do
  use ExUnit.Case

  @moduletag :unit

  alias Moai.Parser.Context.SymbolInfo
  alias Moai.Core.Interpreter.Env

  test "works" do
    context =
      [
        symbols: %{
          "ds" => SymbolInfo.new(%{type: ["date_time"]})
        },
        functions: %{
          nil => %{
            "date_diff_days" => [
              SymbolInfo.new(%{type: {:fun, ["date_time", "date_time", :number]}})
            ]
          }
        }
      ]
      |> Moai.Parser.Context.new()
      |> Moai.Parser.Context.install_type_aliases(%{
        "date_time" => %{
          "year" => :number,
          "month" => :number,
          "day" => :number,
          "hour" => :number,
          "minute" => :number,
          "second" => :number
        }
      })
      |> Moai.Core.Macro.Sigil.BuiltIn.install()

    code = """
    for d in ds ->
      date_diff_days(
        ~d\"2020-01-01T20:12:39\",
        d
      )
    """

    assert {:ok, tokens} = Moai.Tokenizer.tokenize(code)
    assert {:ok, ast} = Moai.Parser.parse(tokens)

    {aast, _acc} =
      Moai.Parser.Ast.traverse(
        ast,
        context,
        &Moai.Core.Macro.expander/2,
        &Moai.Typing.Annotator.annotator/2
      )

    assert :error === Moai.Parser.Ast.extract_meta(aast, :errors)

    env =
      Env.new(
        bindings: %{
          "ds" => [
            %{"year" => 2020, "month" => 1, "day" => 1},
            %{"year" => 2020, "month" => 1, "day" => 2},
            %{"year" => 2020, "month" => 1, "day" => 3}
          ]
        },
        functions: %{nil => %{"date_diff_days" => Env.Function.new(__MODULE__, :date_diff_days)}}
      )

    assert {:ok, [0, -1, -2]} === Moai.Core.Interpreter.eval(aast, env)
  end

  def date_diff_days(date_a, date_b) do
    {:ok, date_a} = Date.from_erl({date_a["year"], date_a["month"], date_a["day"]})
    {:ok, date_b} = Date.from_erl({date_b["year"], date_b["month"], date_b["day"]})

    {:ok, Date.diff(date_a, date_b)}
  end
end
