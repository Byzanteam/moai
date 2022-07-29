defmodule JetExp.Typing.Types do
  @moduledoc false

  @type alias() :: String.t()

  @type t() ::
          JetExp.Typing.Types.BuiltIn.t()
          | JetExp.Typing.Types.List.t()
          | JetExp.Typing.Types.Object.t()
          | JetExp.Typing.Types.Function.t()
end
