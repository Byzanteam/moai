defmodule Moai.Typing.Types do
  @moduledoc false

  @type alias() :: String.t()

  @type t() ::
          Moai.Typing.Types.Primitive.t()
          | Moai.Typing.Types.List.t()
          | Moai.Typing.Types.Object.t()
          | Moai.Typing.Types.Function.t()
end
