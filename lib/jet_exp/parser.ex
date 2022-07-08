defmodule JetExp.Parser do
  @moduledoc false

  @spec parse([JetExp.Tokenizer.token()]) :: {:ok, term()} | {:error, term()}
  def parse(tokens) do
    :jet_exp_parser.parse(tokens)
  end
end
