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

  describe "conditional" do
    test "works" do
      assert {:ok, 1} === eval("if(x, a, b)", %{"x" => true, "a" => 1, "b" => 2})
      assert {:ok, 2} === eval("if(x, a, b)", %{"x" => false, "a" => 1, "b" => 2})

      assert {:ok, nil} === eval("if(x, a)", %{"x" => nil, "a" => 1})
      assert {:ok, nil} === eval("if(x, a)", %{"x" => false, "a" => 1})
      assert {:ok, nil} === eval("if(x, a)", %{"x" => true, "a" => nil})
    end
  end

  describe "call" do
    alias JetExp.Core.Interpreter.Env

    test "works" do
      assert {:ok, 2.0} ===
               eval("avg(1, x)", %{
                 "x" => 3,
                 "avg" => Env.Function.new(__MODULE__, :avg)
               })

      assert {:ok, 2} ===
               eval("avg(1, x)", %{
                 "x" => 3,
                 "avg" => Env.Function.new(__MODULE__, :avg, [:trunc])
               })

      assert {:ok, nil} ===
               eval("avg(1, x)", %{
                 "x" => nil,
                 "avg" => Env.Function.new(__MODULE__, :avg, [:trunc])
               })

      assert {:ok, 0.5} ===
               eval("avg(1, x)", %{
                 "x" => nil,
                 "avg" => Env.Function.new(__MODULE__, :avg, [], require_args: false)
               })
    end

    def avg(a, b)
        when is_nil(a)
        when is_nil(b) do
      avg(a || 0, b || 0)
    end

    def avg(a, b) do
      {:ok, (a + b) / 2}
    end

    def avg(a, b, :trunc) do
      {:ok, trunc((a + b) / 2)}
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
      assert {:ok, nil} === eval("x / y", %{"x" => 1, "y" => 0})
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

  describe "relation" do
    test "works" do
      env = %{"x" => 1, "y" => 2}

      assert {:ok, false} === eval("x > y", env)
      assert {:ok, false} === eval("x >= y", env)
      assert {:ok, true} === eval("x < y", env)
      assert {:ok, true} === eval("x <= y", env)

      env = %{"x" => 2, "y" => 2}

      assert {:ok, false} === eval("x > y", env)
      assert {:ok, true} === eval("x >= y", env)
      assert {:ok, false} === eval("x < y", env)
      assert {:ok, true} === eval("x <= y", env)
    end
  end

  describe "comparison" do
    test "works" do
      assert {:ok, true} === eval("x == y", %{"x" => 1, "y" => 1})
      assert {:ok, false} === eval("x != y", %{"x" => 1, "y" => 1})
      assert {:ok, false} === eval("x == y", %{"x" => 1, "y" => 2})
      assert {:ok, true} === eval("x != y", %{"x" => 1, "y" => 2})

      assert {:ok, true} === eval("x == y", %{"x" => "foo", "y" => "foo"})
      assert {:ok, false} === eval("x != y", %{"x" => "foo", "y" => "foo"})
      assert {:ok, false} === eval("x == y", %{"x" => "foo", "y" => "bar"})
      assert {:ok, true} === eval("x != y", %{"x" => "foo", "y" => "bar"})
    end
  end

  describe "access" do
    test "works" do
      env = %{"obj" => %{"name" => "foo", "age" => 1}}
      assert {:ok, "foo"} === eval("obj.name", env)
      assert {:ok, 1} === eval("obj.age", env)
    end
  end

  describe "list_comp" do
    test "works" do
      assert {:ok, [2, 3, 4]} ===
               eval("for x in xs -> x + 1", %{
                 "xs" => [1, 2, 3]
               })

      assert {:ok, []} === eval("for x in xs -> x + 1", %{"xs" => []})

      assert {:ok, [nil, 2.0, 1.0]} ===
               eval("for x in xs -> 2 / x", %{
                 "xs" => [0, 1, 2]
               })

      assert {:ok, nil} === eval("for x in xs -> x + 1", %{"xs" => nil})
    end
  end

  defp eval(code, bindings \\ %{}) do
    {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    {:ok, ast} = JetExp.Parser.parse(tokens)
    JetExp.Core.Interpreter.eval(ast, JetExp.Core.Interpreter.Env.new(bindings))
  end
end
