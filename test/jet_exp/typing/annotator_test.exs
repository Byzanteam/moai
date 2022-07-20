defmodule JetExp.Typing.AnnotatorTest do
  use ExUnit.Case

  @moduletag :unit

  describe "literal" do
    test "nil" do
      assert {:ok, nil} === extract_type("nil")
    end

    test "bool" do
      assert {:ok, :bool} === extract_type("true")
      assert {:ok, :bool} === extract_type("false")
    end

    test "number" do
      assert {:ok, :number} === extract_type("1")
    end

    test "string" do
      assert {:ok, :string} === extract_type("\"foobar\"")
    end
  end

  describe "identifier" do
    test "works" do
      assert {:ok, :dummy_type} ===
               extract_type("myvar", build_symbol_table(%{"myvar" => %{type: :dummy_type}}))
    end

    test "fails" do
      assert {:error, reason: :not_exists, id: "myvar"} === extract_type("myvar")
    end
  end

  describe "list" do
    test "works" do
      assert {:ok, [:bool]} ===
               extract_type(
                 "[true, x, false, y]",
                 build_symbol_table(%{"x" => %{type: :bool}, "y" => %{type: :bool}})
               )
    end

    test "fails on empty list" do
      assert {:error, reason: :required, value: []} === extract_type("[]")
    end

    test "fails when type slaps" do
      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("[1, 2, a]", build_symbol_table(%{"a" => %{type: :string}}))
    end

    test "synthesize errors" do
      assert {:error, reason: :not_exists, id: "a"} === extract_type("[1, 2, a]")
    end
  end

  describe "list_comp" do
    test "works" do
      assert {:ok, [:number]} ===
               extract_type(
                 "for x in xs -> x",
                 build_symbol_table(%{"xs" => %{type: [:number]}})
               )
    end

    test "fails on non-list source" do
      assert {:error, reason: :type_slaps, expected_type: :"[a]"} ===
               extract_type(
                 "for x in xs -> x",
                 build_symbol_table(%{"xs" => %{type: :number}})
               )
    end
  end

  describe "conditional" do
    test "works" do
      assert {:ok, :dummy_type} ==
               extract_type(
                 "if(true, x)",
                 build_symbol_table(%{"x" => %{type: :dummy_type}})
               )

      assert {:ok, :dummy_type} ==
               extract_type(
                 "if(true, x, y)",
                 build_symbol_table(%{"x" => %{type: :dummy_type}, "y" => %{type: :dummy_type}})
               )
    end

    test "fails on predicate type slaps" do
      assert {:error, reason: :type_slaps, expected_type: :bool} ==
               extract_type(
                 "if(1, x, y)",
                 build_symbol_table(%{"x" => %{type: :dummy_type}, "y" => %{type: :dummy_type}})
               )
    end

    test "fails on type slaps" do
      assert {:error, reason: :type_slaps, expected_type: :dummy_type1} ==
               extract_type(
                 "if(true, x, y)",
                 build_symbol_table(%{"x" => %{type: :dummy_type1}, "y" => %{type: :dummy_type2}})
               )
    end
  end

  describe "call" do
    test "works" do
      symbol_table =
        build_symbol_table(%{
          "dummy_fun" => %{
            type: {:fun, [:number, :bool, :dummy_type]}
          },
          "x" => %{type: :number},
          "y" => %{type: :bool}
        })

      assert {:ok, :dummy_type} === extract_type("dummy_fun(x, y)", symbol_table)
    end

    test "fails when fun not exists" do
      symbol_table =
        build_symbol_table(%{
          "x" => %{type: :number},
          "y" => %{type: :bool}
        })

      assert {:error, reason: :not_exists, id: "dummy_fun"} ===
               extract_type("dummy_fun(x, y)", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table =
        build_symbol_table(%{
          "dummy_fun" => %{
            type: {:fun, [:number, :bool, :dummy_type]}
          },
          "x" => %{type: :dummy_type},
          "y" => %{type: :bool}
        })

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("dummy_fun(x, y)", symbol_table)
    end

    test "fails when calling with incorrect arity" do
      symbol_table =
        build_symbol_table(%{
          "dummy_fun" => %{
            type: {:fun, [:number, :bool, :dummy_type]}
          },
          "x" => %{type: :number}
        })

      assert {:error, reason: :arity, expected_arg_count: 2} ===
               extract_type("dummy_fun(x)", symbol_table)
    end
  end

  describe "call with rest args" do
    test "works" do
      symbol_table =
        build_symbol_table(%{
          "dummy_fun" => %{
            type: {:fun, {:number, :dummy_type}}
          },
          "x" => %{type: :number},
          "y" => %{type: :number}
        })

      assert {:ok, :dummy_type} === extract_type("dummy_fun(x, y)", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table =
        build_symbol_table(%{
          "dummy_fun" => %{
            type: {:fun, {:number, :dummy_type}}
          },
          "x" => %{type: :number},
          "y" => %{type: :bool}
        })

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("dummy_fun(x, y)", symbol_table)
    end
  end

  describe "arith operation" do
    test "works" do
      symbol_table = build_symbol_table(%{"x" => %{type: :number}, "y" => %{type: :number}})

      assert {:ok, :number} === extract_type("x + y", symbol_table)
      assert {:ok, :number} === extract_type("x - y", symbol_table)
      assert {:ok, :number} === extract_type("x * y", symbol_table)
      assert {:ok, :number} === extract_type("x / y", symbol_table)
      assert {:ok, :number} === extract_type("-x", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"x" => %{type: :bool}, "y" => %{type: :number}})

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x + y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x - y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x * y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x / y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("-x", symbol_table)
    end
  end

  describe "logic operation" do
    test "works" do
      symbol_table = build_symbol_table(%{"x" => %{type: :bool}, "y" => %{type: :bool}})

      assert {:ok, :bool} === extract_type("x and y", symbol_table)
      assert {:ok, :bool} === extract_type("x or y", symbol_table)
      assert {:ok, :bool} === extract_type("not x", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"x" => %{type: :number}, "y" => %{type: :bool}})

      assert {:error, reason: :type_slaps, expected_type: :bool} ===
               extract_type("x and y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :bool} ===
               extract_type("x or y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :bool} ===
               extract_type("not x", symbol_table)
    end
  end

  describe "relation operation" do
    test "works" do
      symbol_table = build_symbol_table(%{"x" => %{type: :number}, "y" => %{type: :number}})

      assert {:ok, :bool} === extract_type("x > y", symbol_table)
      assert {:ok, :bool} === extract_type("x >= y", symbol_table)
      assert {:ok, :bool} === extract_type("x < y", symbol_table)
      assert {:ok, :bool} === extract_type("x <= y", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"x" => %{type: :number}, "y" => %{type: :string}})

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x > y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x < y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x >= y", symbol_table)

      assert {:error, reason: :type_slaps, expected_type: :number} ===
               extract_type("x <= y", symbol_table)
    end
  end

  describe "comparison operation" do
    test "works" do
      symbol_table = build_symbol_table(%{"x" => %{type: :string}, "y" => %{type: :string}})

      assert {:ok, :bool} === extract_type("x == y", symbol_table)
      assert {:ok, :bool} === extract_type("x != y", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"x" => %{type: :string}, "y" => %{type: :number}})

      assert {:error, reason: :type_slaps, expected_type: :string} ===
               extract_type("x == y", symbol_table)
    end
  end

  describe "access operation" do
    test "works" do
      symbol_table =
        build_symbol_table(%{
          "obj" => %{
            type: %{
              "name" => :string,
              "age" => :number
            }
          }
        })

      assert {:ok, :string} === extract_type("obj.name", symbol_table)
      assert {:ok, :number} === extract_type("obj.age", symbol_table)

      symbol_table =
        build_symbol_table(%{
          "fun" => %{
            type:
              {:fun,
               [
                 %{
                   "name" => :string,
                   "age" => :number
                 }
               ]}
          }
        })

      assert {:ok, :string} === extract_type("fun().name", symbol_table)
      assert {:ok, :number} === extract_type("fun().age", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"obj" => %{type: :number}})

      assert {:error, reason: :type_slaps, expected_type: :%{}} ===
               extract_type("obj.name", symbol_table)

      symbol_table = build_symbol_table(%{"obj" => %{type: %{"name" => :string}}})

      assert {:error, reason: :key_not_found, keys: ["name"]} ===
               extract_type("obj.age", symbol_table)
    end
  end

  defp extract_type(code, symbol_table \\ JetExp.SymbolTable.new(%{})) do
    {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    {:ok, ast} = JetExp.Parser.parse(tokens)
    aast = JetExp.Typing.Annotator.annotate(ast, symbol_table)
    JetExp.Typing.Annotator.extract_type(aast)
  end

  defp build_symbol_table(symbols) do
    symbols
    |> Map.new(fn {name, info} ->
      {name, JetExp.SymbolTable.SymbolInfo.new(info)}
    end)
    |> JetExp.SymbolTable.new()
  end
end
