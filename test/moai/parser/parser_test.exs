defmodule Moai.ParserTest do
  use ExUnit.Case

  @moduletag :unit

  describe "expr" do
    test "id" do
      assert {:ok, {:id, [line: 1], "my_var"}} === parse("my_var")
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
      assert {:ok, {:sigil, [line: 1], ["d", "2022-01-01"]}} === parse("~d\"2022-01-01\"")
    end

    test "list" do
      assert {:ok, {:"[]", [line: 1], [1, 2, 3]}} === parse("[1, 2, 3]")
    end

    test "op_expr" do
      assert {:ok, {:+, [line: 1], [{:id, [line: 1], "score"}, 3.0]}} === parse("score + 3.0")
    end

    test "call" do
      assert {:ok,
              {{:id, [line: 1], "avg"}, [line: 1],
               [{:id, [line: 1], "score1"}, {:id, [line: 1], "score2"}]}} ===
               parse("avg(score1, score2)")
    end

    test "list_comp" do
      assert {:ok,
              {:for, [line: 1],
               [
                 {:in, [line: 1], [{:id, [line: 1], "s"}, {:id, [line: 1], "s_list"}]},
                 {{:id, [line: 1], "concat"}, [line: 1],
                  [{:id, [line: 1], "s"}, {:id, [line: 1], "suffix"}]}
               ]}} ===
               parse("for s in s_list -> concat(s, suffix)")
    end

    test "group" do
      assert {:ok, {:*, [line: 1], [{:+, [line: 1], [1, 2]}, 3]}} ===
               parse("(1 + 2) * 3")

      assert {:ok, {:-, [line: 1], [10, {:-, [line: 1], [3, 4]}]}} ===
               parse("10 - (3 - 4)")
    end
  end

  describe "list" do
    test "empty" do
      assert {:ok, {:"[]", [line: 1], []}} === parse("[]")
    end

    test "recursion on expr" do
      assert {:ok,
              {:"[]", [line: 1],
               [
                 1,
                 {{:id, [line: 1], "avg"}, [line: 1],
                  [{:id, [line: 1], "score1"}, {:id, [line: 1], "score2"}]},
                 3
               ]}} === parse("[1, avg(score1, score2), 3]")
    end
  end

  describe "operation" do
    test "logical" do
      assert {:ok, {:or, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a or b")

      assert {:ok, {:and, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a and b")

      # associativity
      assert parse("a or b or c") === parse("(a or b) or c")
      assert parse("a and b and c") === parse("(a and b) and c")
      # precedence
      assert parse("a or b and c") === parse("a or (b and c)")
    end

    test "comparison" do
      assert {:ok, {:==, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a == b")

      assert {:ok, {:!=, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a != b")
    end

    test "relation" do
      assert {:ok, {:>, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a > b")

      assert {:ok, {:>=, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a >= b")

      assert {:ok, {:<, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a < b")

      assert {:ok, {:<=, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a <= b")
    end

    test "arithmetic" do
      assert {:ok, {:+, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a + b")

      assert {:ok, {:-, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a - b")

      assert {:ok, {:*, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a * b")

      assert {:ok, {:/, [line: 1], [{:id, [line: 1], "a"}, {:id, [line: 1], "b"}]}} ===
               parse("a / b")

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
      assert {:ok, {:not, [line: 1], [{:id, [line: 1], "a"}]}} === parse("not a")

      assert {:ok, {:id, [line: 1], "a"}} === parse("+a")
      assert {:ok, {:-, [line: 1], [{:id, [line: 1], "a"}]}} === parse("-a")

      assert {:ok, 1} === parse("+1")
      assert {:ok, -1} === parse("-1")
      assert {:ok, false} === parse("not true")
      assert {:ok, true} === parse("not false")
    end

    test "dot" do
      assert {:ok, {:., [line: 1], [{:id, [line: 1], "checkbox"}, {:id, [line: 1], "options"}]}} ===
               parse("checkbox.options")
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
      assert {:ok, {{:id, [line: 1], "fun"}, [line: 1], []}} === parse("fun()")
    end

    test "recursion on expr" do
      assert {:ok,
              {{:id, [line: 1], "avg"}, [line: 1],
               [
                 {:for, [line: 1],
                  [
                    {:in, [line: 1], [{:id, [line: 1], "n"}, {:id, [line: 1], "nums"}]},
                    {:+, [line: 1], [{:id, [line: 1], "n"}, 1]}
                  ]},
                 {:+, [line: 1], [{:id, [line: 1], "num1"}, {:id, [line: 1], "num2"}]}
               ]}} ===
               parse("avg(for n in nums -> n + 1, num1 + num2)")
    end

    test "with namespace" do
      assert {:ok, {{:id, [line: 1], "fun"}, [context: "Ns", line: 1], [1]}} ===
               parse("Ns.fun(1)")
    end
  end

  describe "list_comp" do
    test "recursion on expr" do
      assert {:ok,
              {:for, [line: 1],
               [
                 {:in, [line: 1],
                  [
                    {:id, [line: 1], "i"},
                    {{:id, [line: 1], "running_sum"}, [line: 1], [{:id, [line: 1], "sales"}]}
                  ]},
                 {:*, [line: 1], [{:id, [line: 1], "i"}, 0.8]}
               ]}} ===
               parse("for i in running_sum(sales) -> i * 0.8")
    end
  end

  defp parse(code) do
    assert {:ok, tokens} = Moai.Tokenizer.tokenize(code)
    Moai.Parser.parse(tokens)
  end
end
