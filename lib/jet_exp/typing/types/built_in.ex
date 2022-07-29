defmodule JetExp.Typing.Types.BuiltIn do
  @moduledoc false

  @type t() :: nil | :bool | :number | :string

  @spec all() :: [t(), ...]
  def all do
    [:bool, :number, :string]
  end
end
