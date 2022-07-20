defmodule JetExp.Parser.Context do
  @moduledoc false

  defmodule SymbolInfo do
    @moduledoc false

    @type t() :: %__MODULE__{type: JetExp.Typing.Types.t()}

    @enforce_keys [:type]
    defstruct [:type]

    @spec new(%{required(:type) => JetExp.Typing.Types.t(), optional(term()) => term()}) :: t()
    def new(params) do
      %__MODULE__{
        type: Map.fetch!(params, :type)
      }
    end

    @spec extract(t(), :type) :: JetExp.Typing.Types.t()
    def extract(%__MODULE__{} = symbol_info, :type) do
      symbol_info.type
    end
  end

  @typep name() :: String.t()

  @typep symbols() :: %{required(name()) => SymbolInfo.t()}
  @typep macros() :: %{required(name()) => JetExp.Core.Macro.t()}

  @type t() :: %__MODULE__{
          enclosing: t() | nil,
          symbols: symbols(),
          macros: macros()
        }

  @enforce_keys [:symbols]
  defstruct [
    :enclosing,
    :symbols,
    macros: %{}
  ]

  @spec new(symbols()) :: t()
  def new(symbols) do
    %__MODULE__{symbols: symbols}
  end

  @spec new(symbols(), enclosing :: t()) :: t()
  def new(symbols, enclosing) do
    %__MODULE__{symbols: symbols, enclosing: enclosing}
  end

  @spec install_macros(t(), macros()) :: t()
  def install_macros(%__MODULE__{} = context, macros) do
    Map.update!(context, :macros, &Map.merge(&1, macros))
  end

  @spec lookup_symbol(t(), name()) :: {:ok, SymbolInfo.t()} | :error
  def lookup_symbol(%__MODULE__{enclosing: nil} = context, name) do
    Map.fetch(context.symbols, name)
  end

  def lookup_symbol(%__MODULE__{} = context, name) do
    with(:error <- Map.fetch(context.symbols, name)) do
      lookup_symbol(context.enclosing, name)
    end
  end

  @spec lookup_macro(t(), name()) :: {:ok, JetExp.Core.Macro.t()} | :error
  def lookup_macro(%__MODULE__{enclosing: nil} = context, name) do
    Map.fetch(context.macros, name)
  end

  def lookup_macro(%__MODULE__{} = context, name) do
    with(:error <- Map.fetch(context.macros, name)) do
      lookup_macro(context.enclosing, name)
    end
  end

  @spec declare(t(), name(), SymbolInfo.t()) :: {:ok, t()} | :error
  def declare(%__MODULE__{} = table, name, info) do
    if Map.has_key?(table.symbols, name) do
      :error
    else
      Map.update!(table, :symbols, &Map.put(&1, name, info))
    end
  end
end
