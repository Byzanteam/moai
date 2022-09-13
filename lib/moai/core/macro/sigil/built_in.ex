defmodule Moai.Core.Macro.Sigil.BuiltIn do
  @moduledoc false

  alias Moai.Parser.Context
  alias Moai.Core.Macro.Sigil

  @sigils %{
    "d" => Sigil.Date
  }

  @sigil_macros Map.new(@sigils, fn {sigil_name, module} ->
                  {Moai.Core.Macro.Sigil.to_macro_name(sigil_name), module}
                end)

  @spec install(Context.t()) :: Context.t()
  def install(context) do
    Context.install_macros(context, @sigil_macros)
  end
end
