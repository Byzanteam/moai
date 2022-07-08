defmodule JetExp.TokenizerTest do
  use ExUnit.Case

  @code """
  my_var my_var' MyVar1
  nil
  true false
  10 01
  1.0 0.1 0000.1
  \"foo\" \"\\\"foo\\\"\"
  ~d\"2022-01-01\"
  for n in nums -> n + 1
  and or not
  , . ( ) [ ]
  + - * /
  == != > < >= <=
  """

  @tag :unit
  test "tokenize/1" do
    assert tokenize(@code) ===
             {:ok,
              [
                {:id, "my_var"},
                {:id, "my_var'"},
                {:id, "MyVar1"},
                nil,
                {:bool, true},
                {:bool, false},
                {:number, 10},
                {:number, 1},
                {:number, 1.0},
                {:number, 0.1},
                {:number, 0.1},
                {:string, "foo"},
                {:string, "\\\"foo\\\""},
                {:sigil, "~d"},
                {:string, "2022-01-01"},
                # begin: for n in nums -> n + 1
                :for,
                {:id, "n"},
                :in,
                {:id, "nums"},
                :->,
                {:id, "n"},
                :+,
                {:number, 1},
                # end
                :and,
                :or,
                :not,
                :",",
                :.,
                :"(",
                :")",
                :"[",
                :"]",
                :+,
                :-,
                :*,
                :/,
                :==,
                :!=,
                :>,
                :<,
                :>=,
                :<=
              ]}
  end

  defp tokenize(code) do
    with {:ok, tokens} <- JetExp.Tokenizer.tokenize(code) do
      {:ok,
       Enum.map(tokens, fn
         {category, _line} -> category
         {category, _line, value} -> {category, value}
       end)}
    end
  end
end
