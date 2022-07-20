defmodule JetExp.Core.Macro.Sigil do
  @moduledoc false

  alias JetExp.Parser.Ast
  alias JetExp.Parser.Context

  @type name() :: String.t()
  @type errors() :: Keyword.t()

  @spec lookup_sigil(Context.t(), sigil :: Ast.sigil_node()) ::
          {:ok, JetExp.Core.Macro.t()} | {:error, errors()}
  def lookup_sigil(context, sigil) do
    [sigil_name, _sigil_arg] = Ast.sigil_args(sigil)

    with(:error <- Context.lookup_macro(context, to_macro_name(sigil_name))) do
      {:error, reason: :not_found, id: sigil_name}
    end
  end

  @spec to_macro_name(sigil_name :: name()) :: JetExp.Core.Macro.name()
  def to_macro_name(sigil_name) do
    "sigil_" <> sigil_name
  end

  @callback eval(Ast.t()) :: {:ok, Ast.t()} | {:error, errors()}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour JetExp.Core.Macro

      @impl JetExp.Core.Macro
      def run(node, _context) do
        [_sigil_name, arg] = JetExp.Parser.Ast.sigil_args(node)
        eval(arg)
      end

      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def eval(_arg), do: raise("Not implemented")

      defoverridable unquote(__MODULE__)
    end
  end
end
