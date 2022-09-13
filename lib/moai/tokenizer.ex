defmodule Moai.Tokenizer do
  @moduledoc false

  @typep code() :: String.t()

  @typep token_keyword() :: :for | :in | :->
  @typep token_operator() ::
           :","
           | :"("
           | :")"
           | :"["
           | :"]"
           | :.
           | :+
           | :-
           | :*
           | :/
           | :==
           | :!=
           | :>
           | :<
           | :>=
           | :<=

  @typep token_category() ::
           token_keyword() | token_operator() | :id | nil | :bool | :number | :string | :sigil

  @typep token_value() :: String.t() | boolean() | number()

  @typep token_line() :: pos_integer()

  @type token() ::
          {token_category(), token_line()} | {token_category(), token_line(), token_value()}

  @spec tokenize(code()) :: {:ok, [token()]} | {:error, reason :: term()}
  def tokenize(code) do
    with({:ok, tokens, _end_line} <- code |> to_charlist() |> :moai_tokenizer.string()) do
      {:ok, tokens}
    end
  end
end
