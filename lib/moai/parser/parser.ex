defmodule Moai.Parser do
  @moduledoc false

  @spec parse([Moai.Tokenizer.token()]) :: {:ok, term()} | {:error, term()}
  def parse(tokens) do
    :moai_parser.parse(tokens)
  end
end
