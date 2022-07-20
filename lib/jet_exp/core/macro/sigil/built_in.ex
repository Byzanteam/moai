defmodule JetExp.Core.Macro.Sigil.BuiltIn do
  @moduledoc false

  alias JetExp.Parser.Context
  alias JetExp.Core.Macro.Sigil

  @sigils %{
    "d" => Sigil.Date
  }

  @sigil_macros Map.new(@sigils, fn {sigil_name, module} ->
                  {JetExp.Core.Macro.Sigil.to_macro_name(sigil_name), module}
                end)

  @spec install(Context.t()) :: Context.t()
  def install(context) do
    Context.install_macros(context, @sigil_macros)
  end
end
