defmodule JetExp.Core.Library.Builder do
  @moduledoc false

  @spec __using__(namespace: String.t() | nil) :: Macro.t()
  defmacro __using__(opts) do
    namespace = Keyword.get(opts, :namespace)

    quote location: :keep do
      @before_compile unquote(__MODULE__)

      @__lib_namespace__ unquote(namespace)

      Module.register_attribute(__MODULE__, :fun_meta, accumulate: true)
    end
  end

  defmacro __before_compile__(env) do
    namespace = Module.get_attribute(env.module, :__lib_namespace__)
    fun_meta = Module.delete_attribute(env.module, :fun_meta)

    fun_symbols = fun_meta |> build_fun_symbols(namespace) |> Macro.escape()
    fun_bindings = fun_meta |> build_fun_bindings(env.module, namespace) |> Macro.escape()

    quote location: :keep do
      @spec install_symbols(context) :: context when context: JetExp.Parser.Context.t()
      def install_symbols(context) do
        JetExp.Parser.Context.install_functions(context, unquote(fun_symbols))
      end

      @spec install_bindings(env) :: env when env: JetExp.Core.Interpreter.Env.t()
      def install_bindings(env) do
        JetExp.Core.Interpreter.Env.install_functions(env, unquote(fun_bindings))
      end
    end
  end

  defp build_fun_symbols(fun_meta, namespace) do
    %{
      namespace =>
        Map.new(fun_meta, fn {fun_name, meta} ->
          {
            Atom.to_string(fun_name),
            [
              JetExp.Parser.Context.SymbolInfo.new(%{
                type: {:fun, Keyword.fetch!(meta, :signature)}
              })
            ]
          }
        end)
    }
  end

  @default_extra_args []
  @default_fun_opts [require_args: true]

  defp build_fun_bindings(fun_meta, module, namespace) do
    %{
      namespace =>
        Map.new(fun_meta, fn {fun_name, meta} ->
          {
            Atom.to_string(fun_name),
            JetExp.Core.Interpreter.Env.Function.new(
              module,
              Keyword.get(meta, :impl, fun_name),
              Keyword.get(meta, :extra_args, @default_extra_args),
              Keyword.get(meta, :opts, @default_fun_opts)
            )
          }
        end)
    }
  end
end
