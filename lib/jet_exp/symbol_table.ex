defmodule JetExp.SymbolTable do
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

  @type t() :: %__MODULE__{symbols: symbols(), surrounding: t() | nil}

  @enforce_keys [:symbols]
  defstruct [:symbols, :surrounding]

  @spec new(symbols()) :: t()
  def new(symbols) do
    %__MODULE__{symbols: symbols}
  end

  @spec new(symbols(), surrounding :: t()) :: t()
  def new(symbols, surrounding) do
    %__MODULE__{symbols: symbols, surrounding: surrounding}
  end

  @spec lookup(t(), name()) :: {:ok, SymbolInfo.t()} | :error
  def lookup(%__MODULE__{} = table, name) do
    case Map.fetch(table.symbols, name) do
      {:ok, info} ->
        {:ok, info}

      :error ->
        if is_nil(table.surrounding) do
          :error
        else
          lookup(table.surrounding, name)
        end
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
