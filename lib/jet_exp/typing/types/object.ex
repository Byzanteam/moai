defmodule JetExp.Typing.Types.Object do
  @moduledoc false

  @typep field() :: String.t()
  @type t() :: %{required(field()) => JetExp.Typing.Types.t()}
end
