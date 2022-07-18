defmodule JetExp.Typing.Types.Function do
  @moduledoc false

  @type t() ::
          {:fun, [JetExp.Typing.Types.t()]}
          | {:fun, {JetExp.Typing.Types.t(), JetExp.Typing.Types}}
end