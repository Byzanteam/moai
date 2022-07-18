defmodule JetExp.Core.InterpreterTest do
  use ExUnit.Case

  @moduletag false

  describe "literal" do
    test "nil" do
      assert {:ok, nil} === eval("nil")
    end

    test "bool" do
      assert {:ok, true} === eval("true")
      assert {:ok, false} === eval("false")
    end

    test "number" do
      assert {:ok, 1} === eval("1")
      assert {:ok, -1.0} === eval("-1.0")
    end

    test "string" do
      assert {:ok, "foobar"} === eval("\"foobar\"")
    end
  end

  describe "variable" do
    test "works" do
      assert {:ok, 1} === eval("myvar", %{"myvar" => 1})
    end

    test "fails" do
      assert :error === eval("myvar")
    end
  end

  describe "list" do
    test "works" do
      assert {:ok, [1, 2]} === eval("[1, 2]")
      assert {:ok, [1, 2]} === eval("[x, y]", %{"x" => 1, "y" => 2})
      assert {:ok, [1, nil]} === eval("[x, nil]", %{"x" => 1})
    end

    test "fails" do
      assert :error === eval("[1, x]")
    end
  end

  describe "arith" do
    test "works" do
      assert {:ok, 5} === eval("x + y", %{"x" => 2, "y" => 3})
      assert {:ok, -1} === eval("x - y", %{"x" => 2, "y" => 3})
      assert {:ok, 6} === eval("x * y", %{"x" => 2, "y" => 3})
      assert {:ok, 1.5} === eval("x / y", %{"x" => 3, "y" => 2})
      assert {:ok, -1} === eval("-x", %{"x" => 1})
    end

    test "fails when dividing by 0" do
      assert :error === eval("x / y", %{"x" => 1, "y" => 0})
    end
  end

  describe "logic" do
    test "and" do
      assert {:ok, true} === eval("x and y", %{"x" => true, "y" => true})
      assert {:ok, false} === eval("x and y", %{"x" => true, "y" => false})
      assert {:ok, false} === eval("x and y", %{"x" => false, "y" => true})
      assert {:ok, false} === eval("x and y", %{"x" => false, "y" => false})

      assert {:ok, nil} === eval("x and y", %{"x" => true, "y" => nil})
      assert {:ok, false} === eval("x and y", %{"x" => false, "y" => nil})
    end

    test "or" do
      assert {:ok, true} === eval("x or y", %{"x" => true, "y" => true})
      assert {:ok, true} === eval("x or y", %{"x" => true, "y" => false})
      assert {:ok, true} === eval("x or y", %{"x" => false, "y" => true})
      assert {:ok, false} === eval("x or y", %{"x" => false, "y" => false})

      assert {:ok, nil} === eval("x or y", %{"x" => nil, "y" => true})
      assert {:ok, true} === eval("x or y", %{"x" => true, "y" => nil})
    end

    test "not" do
      assert {:ok, false} === eval("not x", %{"x" => true})
      assert {:ok, true} === eval("not x", %{"x" => false})
      assert {:ok, nil} === eval("not x", %{"x" => nil})
    end
  end

  defp eval(code, bindings \\ %{}) do
    {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    {:ok, ast} = JetExp.Parser.parse(tokens)
    JetExp.Core.Interpreter.eval(ast, JetExp.Core.Interpreter.Env.new(bindings))
  end
end
