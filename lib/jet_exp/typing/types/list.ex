defmodule JetExp.Typing.Types.List do
  @moduledoc false

  @type t() :: [JetExp.Typing.Types.t() | JetExp.Typing.Types.alias()]
end
