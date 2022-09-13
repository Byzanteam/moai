defmodule Moai.Typing.Types.Object do
  @moduledoc false

  @typep field() :: String.t()
  @type t() :: %{required(field()) => Moai.Typing.Types.t() | Moai.Typing.Types.alias()}
end
