defmodule Moai.Core.Library.Kernel do
  @moduledoc false

  @doc """
  Returns true if value is nil, false otherwise.

  ## Examples

    iex> k_is_nil(1)
    {:ok, false}

    iex> k_is_nil("a")
    {:ok, false}

    iex> k_is_nil([nil])
    {:ok, false}

    iex> k_is_nil([])
    {:ok, false}

    iex> k_is_nil(nil)
    {:ok, true}
  """
  @spec k_is_nil(term()) :: {:ok, boolean()}
  def k_is_nil(term) do
    {:ok, is_nil(term)}
  end

  alias Moai.Parser.Context

  @spec install_symbols(Context.t()) :: Context.t()
  def install_symbols(context) do
    Context.install_functions(context, build_fun_symbols(context))
  end

  defp build_fun_symbols(context) do
    type_aliases = context.type_aliases
    types_and_aliases = [nil | Moai.Typing.Types.Primitive.all() ++ Map.keys(type_aliases)]

    functions =
      Enum.map(types_and_aliases, fn t ->
        signature = [t, :bool]
        Context.SymbolInfo.new(%{type: {:fun, signature}})
      end)

    %{
      nil => %{
        "is_nil" => functions
      }
    }
  end

  alias Moai.Core.Interpreter.Env

  @bindings %{
    nil => %{
      "is_nil" =>
        Env.Function.new(
          __MODULE__,
          :k_is_nil,
          [],
          require_args: false
        )
    }
  }

  @spec install_bindings(Env.t()) :: Env.t()
  def install_bindings(env) do
    Env.install_functions(env, @bindings)
  end
end
