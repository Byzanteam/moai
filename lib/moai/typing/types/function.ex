defmodule Moai.Typing.Types.Function do
  @moduledoc false

  @type t() :: {:fun, [Moai.Typing.Types.t() | Moai.Typing.Types.alias()]}
end
