defmodule JetExp.ParserTest do
  use ExUnit.Case

  @moduletag :unit

  describe "expr" do
    test "id" do
      assert {:ok, "my_var"} === parse("my_var")
    end

    test "nil" do
      assert {:ok, nil} === parse("nil")
    end

    test "bool" do
      assert {:ok, {:bool, true}} === parse("true")
      assert {:ok, {:bool, false}} === parse("false")
    end

    test "number" do
      assert {:ok, {:number, 10}} === parse("10")
      assert {:ok, {:number, 10.01}} === parse("10.01")
    end

    test "string" do
      assert {:ok, {:string, ""}} === parse("\"\"")
      assert {:ok, {:string, "foobar"}} === parse("\"foobar\"")
    end

    test "sigil" do
      assert {:ok, {:sigil, {"~d", {:string, "2022-01-01"}}}} === parse("~d\"2022-01-01\"")
    end

    test "list" do
      assert {:ok, [{:number, 1}, {:number, 2}, {:number, 3}]} ===
               parse("[1, 2, 3]")
    end

    test "op_expr" do
      assert {:ok, {:+, ["score", {:number, 3.0}]}} === parse("score + 3.0")
    end

    test "call" do
      assert {:ok, {"avg", ["score1", "score2"]}} === parse("avg(score1, score2)")
    end

    test "list_comp" do
      assert {:ok, {:map, ["s_list", {"concat", ["s", "suffix"]}, "s"]}} ===
               parse("for s in s_list -> concat(s, suffix)")
    end

    test "group" do
      assert {:ok, {:*, [{:+, [{:number, 1}, {:number, 2}]}, {:number, 3}]}} ===
               parse("(1 + 2) * 3")

      assert {:ok, {:-, [{:number, 10}, {:-, [{:number, 3}, {:number, 4}]}]}} ===
               parse("10 - (3 - 4)")
    end
  end

  describe "list" do
    test "empty" do
      assert {:ok, []} === parse("[]")
    end

    test "recursion on expr" do
      assert {:ok,
              [
                {:number, 1},
                {"avg", ["score1", "score2"]},
                {:number, 3}
              ]} === parse("[1, avg(score1, score2), 3]")
    end
  end

  describe "operation" do
    test "logical" do
      assert {:ok, {:or, ["a", "b"]}} === parse("a or b")
      assert {:ok, {:and, ["a", "b"]}} === parse("a and b")

      # associativity
      assert parse("a or b or c") === parse("(a or b) or c")
      assert parse("a and b and c") === parse("(a and b) and c")
      # precedence
      assert parse("a or b and c") === parse("a or (b and c)")
    end

    test "comparison" do
      assert {:ok, {:==, ["a", "b"]}} === parse("a == b")
      assert {:ok, {:!=, ["a", "b"]}} === parse("a != b")
    end

    test "relation" do
      assert {:ok, {:>, ["a", "b"]}} === parse("a > b")
      assert {:ok, {:>=, ["a", "b"]}} === parse("a >= b")
      assert {:ok, {:<, ["a", "b"]}} === parse("a < b")
      assert {:ok, {:<=, ["a", "b"]}} === parse("a <= b")
    end

    test "arithmetic" do
      assert {:ok, {:+, ["a", "b"]}} === parse("a + b")
      assert {:ok, {:-, ["a", "b"]}} === parse("a - b")
      assert {:ok, {:*, ["a", "b"]}} === parse("a * b")
      assert {:ok, {:/, ["a", "b"]}} === parse("a / b")

      # associativity
      assert parse("a + b + c") === parse("(a + b) + c")
      assert parse("a - b - c") === parse("(a - b) - c")
      assert parse("a + b - c") === parse("(a + b) - c")
      assert parse("a - b + c") === parse("(a - b) + c")

      assert parse("a * b * c") === parse("(a * b) * c")
      assert parse("a / b / c") === parse("(a / b) / c")
      assert parse("a * b / c") === parse("(a * b) / c")
      assert parse("a / b * c") === parse("(a / b) * c")

      # precedence
      assert parse("a + b * c") === parse("a + (b * c)")
      assert parse("a - b * c") === parse("a - (b * c)")
      assert parse("a + b / c") === parse("a + (b / c)")
      assert parse("a - b / c") === parse("a - (b / c)")
    end

    test "unary" do
      assert {:ok, {:not, ["a"]}} === parse("not a")

      assert {:ok, "a"} === parse("+a")
      assert {:ok, {:-, ["a"]}} === parse("-a")

      assert {:ok, {:number, 1}} === parse("+1")
      assert {:ok, {:number, -1}} === parse("-1")
    end

    test "dot" do
      assert {:ok, {:access, ["checkbox", "options"]}} === parse("checkbox.options")
    end

    test "precedence" do
      assert parse("(a + b) == c") === parse("a + b == c")
      assert parse("(a + b) > c") === parse("a + b > c")
      assert parse("((a + b) > c) or ((a - b) < d)") === parse("a + b > c or a - b < d")
      assert parse("(not a) and b") === parse("not a and b")
      assert parse("a * (-b)") === parse("a * -b")
    end
  end

  describe "call" do
    test "0 args" do
      assert {:ok, {"fun", []}} === parse("fun()")
    end

    test "recursion on expr" do
      assert {:ok,
              {"avg",
               [
                 {:map, ["nums", {:+, ["n", {:number, 1}]}, "n"]},
                 {:+, ["num1", "num2"]}
               ]}} ===
               parse("avg(for n in nums -> n + 1, num1 + num2)")
    end
  end

  describe "list_comp" do
    test "recursion on expr" do
      assert {:ok, {:map, [{"running_sum", ["sales"]}, {:*, ["i", {:number, 0.8}]}, "i"]}} ===
               parse("for i in running_sum(sales) -> i * 0.8")
    end
  end

  defp parse(code) do
    assert {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    JetExp.Parser.parse(tokens)
  end
end
