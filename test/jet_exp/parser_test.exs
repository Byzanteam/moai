defmodule JetExp.ParserTest do
  use ExUnit.Case

  @moduletag :unit

  describe "expr" do
    test "id" do
      assert {:ok, {:id, "my_var"}} === parse("my_var")
    end

    test "nil" do
      assert {:ok, nil} === parse("nil")
    end

    test "bool" do
      assert {:ok, true} === parse("true")
      assert {:ok, false} === parse("false")
    end

    test "number" do
      assert {:ok, 10} === parse("10")
      assert {:ok, 10.01} === parse("10.01")
    end

    test "string" do
      assert {:ok, ""} === parse("\"\"")
      assert {:ok, "foobar"} === parse("\"foobar\"")
    end

    test "sigil" do
      assert {:ok, {:sigil, {"~d", "2022-01-01"}}} === parse("~d\"2022-01-01\"")
    end

    test "list" do
      assert {:ok, {:"[]", [1, 2, 3]}} === parse("[1, 2, 3]")
    end

    test "op_expr" do
      assert {:ok, {:+, [{:id, "score"}, 3.0]}} === parse("score + 3.0")
    end

    test "call" do
      assert {:ok, {{:id, "avg"}, [{:id, "score1"}, {:id, "score2"}]}} ===
               parse("avg(score1, score2)")
    end

    test "list_comp" do
      assert {:ok,
              {:for,
               [
                 {:in, [{:id, "s"}, {:id, "s_list"}]},
                 {{:id, "concat"}, [{:id, "s"}, {:id, "suffix"}]}
               ]}} ===
               parse("for s in s_list -> concat(s, suffix)")
    end

    test "group" do
      assert {:ok, {:*, [{:+, [1, 2]}, 3]}} ===
               parse("(1 + 2) * 3")

      assert {:ok, {:-, [10, {:-, [3, 4]}]}} ===
               parse("10 - (3 - 4)")
    end
  end

  describe "list" do
    test "empty" do
      assert {:ok, {:"[]", []}} === parse("[]")
    end

    test "recursion on expr" do
      assert {:ok,
              {:"[]",
               [
                 1,
                 {{:id, "avg"}, [{:id, "score1"}, {:id, "score2"}]},
                 3
               ]}} === parse("[1, avg(score1, score2), 3]")
    end
  end

  describe "operation" do
    test "logical" do
      assert {:ok, {:or, [{:id, "a"}, {:id, "b"}]}} === parse("a or b")
      assert {:ok, {:and, [{:id, "a"}, {:id, "b"}]}} === parse("a and b")

      # associativity
      assert parse("a or b or c") === parse("(a or b) or c")
      assert parse("a and b and c") === parse("(a and b) and c")
      # precedence
      assert parse("a or b and c") === parse("a or (b and c)")
    end

    test "comparison" do
      assert {:ok, {:==, [{:id, "a"}, {:id, "b"}]}} === parse("a == b")
      assert {:ok, {:!=, [{:id, "a"}, {:id, "b"}]}} === parse("a != b")
    end

    test "relation" do
      assert {:ok, {:>, [{:id, "a"}, {:id, "b"}]}} === parse("a > b")
      assert {:ok, {:>=, [{:id, "a"}, {:id, "b"}]}} === parse("a >= b")
      assert {:ok, {:<, [{:id, "a"}, {:id, "b"}]}} === parse("a < b")
      assert {:ok, {:<=, [{:id, "a"}, {:id, "b"}]}} === parse("a <= b")
    end

    test "arithmetic" do
      assert {:ok, {:+, [{:id, "a"}, {:id, "b"}]}} === parse("a + b")
      assert {:ok, {:-, [{:id, "a"}, {:id, "b"}]}} === parse("a - b")
      assert {:ok, {:*, [{:id, "a"}, {:id, "b"}]}} === parse("a * b")
      assert {:ok, {:/, [{:id, "a"}, {:id, "b"}]}} === parse("a / b")

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
      assert {:ok, {:not, [{:id, "a"}]}} === parse("not a")

      assert {:ok, {:id, "a"}} === parse("+a")
      assert {:ok, {:-, [{:id, "a"}]}} === parse("-a")

      assert {:ok, 1} === parse("+1")
      assert {:ok, -1} === parse("-1")
      assert {:ok, false} === parse("not true")
      assert {:ok, true} === parse("not false")
    end

    test "dot" do
      assert {:ok, {:access, [{:id, "checkbox"}, {:id, "options"}]}} === parse("checkbox.options")
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
      assert {:ok, {{:id, "fun"}, []}} === parse("fun()")
    end

    test "recursion on expr" do
      assert {:ok,
              {{:id, "avg"},
               [
                 {:for, [{:in, [{:id, "n"}, {:id, "nums"}]}, {:+, [{:id, "n"}, 1]}]},
                 {:+, [{:id, "num1"}, {:id, "num2"}]}
               ]}} ===
               parse("avg(for n in nums -> n + 1, num1 + num2)")
    end
  end

  describe "list_comp" do
    test "recursion on expr" do
      assert {:ok,
              {:for,
               [
                 {:in, [{:id, "i"}, {{:id, "running_sum"}, [{:id, "sales"}]}]},
                 {:*, [{:id, "i"}, 0.8]}
               ]}} ===
               parse("for i in running_sum(sales) -> i * 0.8")
    end
  end

  defp parse(code) do
    assert {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    JetExp.Parser.parse(tokens)
  end
end
