defmodule JetExp.Core.Library.Builder do
  @moduledoc false

  defmacro __using__(_opts) do
    quote location: :keep do
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :fun_meta, accumulate: true)
    end
  end

  defmacro __before_compile__(env) do
    fun_meta = Module.delete_attribute(env.module, :fun_meta)

    fun_symbols = fun_meta |> build_fun_symbols() |> Macro.escape()
    fun_bindings = fun_meta |> build_fun_bindings(env.module) |> Macro.escape()

    quote location: :keep do
      @spec install_symbols(context) :: context when context: JetExp.Parser.Context.t()
      def install_symbols(context) do
        JetExp.Parser.Context.install_functions(context, unquote(fun_symbols))
      end

      @spec install_bindings(env) :: env when env: JetExp.Core.Interpreter.Env.t()
      def install_bindings(env) do
        JetExp.Core.Interpreter.Env.install_bindings(env, unquote(fun_bindings))
      end
    end
  end

  defp build_fun_symbols(fun_meta) do
    Map.new(fun_meta, fn {fun_name, meta} ->
      {
        Atom.to_string(fun_name),
        JetExp.Parser.Context.SymbolInfo.new(%{
          type: {:fun, Keyword.fetch!(meta, :signature)}
        })
      }
    end)
  end

  @default_extra_args []
  @default_fun_opts [require_args: true, variadic: false]

  defp build_fun_bindings(fun_meta, module) do
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
  end
end
