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
      assert {:error, line: 1, reason: :not_exists, id: "myvar"} === extract_type("myvar")
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
      assert {:error, line: 1, reason: :required, value: []} === extract_type("[]")
    end

    test "fails when type slaps" do
      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("[1, 2, a]", build_symbol_table(%{"a" => %{type: :string}}))
    end

    test "synthesize errors" do
      assert {:error, line: 1, reason: :not_exists, id: "a"} === extract_type("[1, 2, a]")
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
      assert {:error, line: 1, reason: :type_slaps, expected_type: :"[a]"} ===
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
      assert {:error, line: 1, reason: :type_slaps, expected_type: :bool} ==
               extract_type(
                 "if(1, x, y)",
                 build_symbol_table(%{"x" => %{type: :dummy_type}, "y" => %{type: :dummy_type}})
               )
    end

    test "fails on type slaps" do
      assert {:error, line: 1, reason: :type_slaps, expected_type: :dummy_type1} ==
               extract_type(
                 "if(true, x, y)",
                 build_symbol_table(%{"x" => %{type: :dummy_type1}, "y" => %{type: :dummy_type2}})
               )
    end
  end

  describe "call" do
    test "works" do
      symbol_table =
        build_symbol_table(
          %{
            "x" => %{type: :number},
            "y" => %{type: :bool}
          },
          %{
            "dummy_fun" => %{
              type: {:fun, [:number, :bool, :dummy_type]}
            }
          }
        )

      assert {:ok, :dummy_type} === extract_type("dummy_fun(x, y)", symbol_table)
    end

    test "fails when fun not exists" do
      symbol_table =
        build_symbol_table(%{
          "x" => %{type: :number},
          "y" => %{type: :bool}
        })

      assert {:error, line: 1, reason: :not_exists, id: "dummy_fun"} ===
               extract_type("dummy_fun(x, y)", symbol_table)

      symbol_table =
        build_symbol_table(
          %{
            "x" => %{type: :dummy_type},
            "y" => %{type: :bool}
          },
          %{
            "dummy_fun" => %{
              type: {:fun, [:number, :bool, :dummy_type]}
            }
          }
        )

      assert {:error, line: 1, reason: :not_exists, id: "dummy_fun"} ===
               extract_type("dummy_fun(x, y)", symbol_table)

      symbol_table =
        build_symbol_table(
          %{
            "x" => %{type: :number}
          },
          %{
            "dummy_fun" => %{
              type: {:fun, [:number, :bool, :dummy_type]}
            }
          }
        )

      assert {:error, line: 1, reason: :not_exists, id: "dummy_fun"} ===
               extract_type("dummy_fun(x)", symbol_table)
    end
  end

  describe "call with overloading" do
    test "works" do
      symbol_table =
        build_symbol_table(
          %{
            "x" => %{type: :number},
            "y" => %{type: :number},
            "z" => %{type: :string}
          },
          %{
            "dummy_fun" => [
              %{type: {:fun, [:number, :number]}},
              %{type: {:fun, [:number, :number, :bool]}},
              %{type: {:fun, [:number, :string, :string]}}
            ]
          }
        )

      assert {:ok, :number} === extract_type("dummy_fun(x)", symbol_table)
      assert {:ok, :bool} === extract_type("dummy_fun(x, y)", symbol_table)
      assert {:ok, :string} === extract_type("dummy_fun(x, z)", symbol_table)
    end

    test "fails" do
      symbol_table =
        build_symbol_table(
          %{
            "x" => %{type: :number},
            "y" => %{type: :string}
          },
          %{
            "dummy_fun" => [
              %{type: {:fun, [:number, :number]}},
              %{type: {:fun, [:number, :number, :bool]}},
              %{type: {:fun, [:number, :string, :string]}},
              %{type: {:fun, {:number, :number}}}
            ]
          }
        )

      assert {:error, line: 1, reason: :not_exists, id: "dummy_fun"} ===
               extract_type("dummy_fun(y, x)", symbol_table)
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

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x + y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x - y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x * y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x / y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
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

      assert {:error, line: 1, reason: :type_slaps, expected_type: :bool} ===
               extract_type("x and y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :bool} ===
               extract_type("x or y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :bool} ===
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

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x > y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x < y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
               extract_type("x >= y", symbol_table)

      assert {:error, line: 1, reason: :type_slaps, expected_type: :number} ===
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

      assert {:error, line: 1, reason: :type_slaps, expected_type: :string} ===
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
        build_symbol_table(%{}, %{
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

    test "works with type aliases" do
      alias JetExp.Parser.Context

      symbol_table =
        [
          symbols: %{"obj" => Context.SymbolInfo.new(%{type: "dummy_obj"})},
          functions: %{
            "fun" => [Context.SymbolInfo.new(%{type: {:fun, ["dummy_obj"]}})]
          }
        ]
        |> Context.new()
        |> Context.install_type_aliases(%{"dummy_obj" => %{"name" => :string, "age" => :number}})

      assert {:ok, :string} === extract_type("obj.name", symbol_table)
      assert {:ok, :number} === extract_type("obj.age", symbol_table)

      assert {:ok, :string} === extract_type("fun().name", symbol_table)
      assert {:ok, :number} === extract_type("fun().age", symbol_table)
    end

    test "fails on type slaps" do
      symbol_table = build_symbol_table(%{"obj" => %{type: :number}})

      assert {:error, line: 1, reason: :type_slaps, expected_type: :%{}} ===
               extract_type("obj.name", symbol_table)

      symbol_table = build_symbol_table(%{"obj" => %{type: %{"name" => :string}}})

      assert {:error, line: 1, reason: :key_not_found, keys: ["name"]} ===
               extract_type("obj.age", symbol_table)
    end
  end

  defp extract_type(code, symbol_table \\ JetExp.Parser.Context.new([])) do
    {:ok, tokens} = JetExp.Tokenizer.tokenize(code)
    {:ok, ast} = JetExp.Parser.parse(tokens)

    {aast, _acc} =
      JetExp.Parser.Ast.postwalk(ast, symbol_table, &JetExp.Typing.Annotator.annotator/2)

    JetExp.Typing.Annotator.extract_type(aast)
  end

  defp build_symbol_table(symbols, functions \\ %{}) do
    symbols =
      Map.new(symbols, fn {name, info} ->
        {name, JetExp.Parser.Context.SymbolInfo.new(info)}
      end)

    functions =
      Map.new(functions, fn
        {name, [_ | _] = infos} ->
          {name, Enum.map(infos, &JetExp.Parser.Context.SymbolInfo.new/1)}

        {name, info} ->
          {name, [JetExp.Parser.Context.SymbolInfo.new(info)]}
      end)

    JetExp.Parser.Context.new(symbols: symbols, functions: functions)
  end
end
