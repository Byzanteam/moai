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
  @typep functions() :: %{required(name()) => [SymbolInfo.t(), ...]}
  @typep macros() :: %{required(name()) => JetExp.Core.Macro.t()}

  @type t() :: %__MODULE__{
          enclosing: t() | nil,
          symbols: symbols(),
          functions: functions(),
          macros: macros()
        }

  defstruct [
    :enclosing,
    :symbols,
    :functions,
    :macros
  ]

  @typep new_params :: [
           symbols: symbols(),
           functions: functions(),
           macros: macros()
         ]

  @spec new(new_params()) :: t()
  def new(params) do
    symbols = Keyword.get(params, :symbols, %{})
    functions = Keyword.get(params, :functions, %{})
    macros = Keyword.get(params, :macros, %{})

    %__MODULE__{symbols: symbols, functions: functions, macros: macros}
  end

  @spec new(enclosing :: t(), new_params()) :: t()
  def new(enclosing, params) do
    %{new(params) | enclosing: enclosing}
  end

  @spec install_functions(t(), functions()) :: t()
  def install_functions(%__MODULE__{} = context, functions) do
    Map.update!(
      context,
      :functions,
      &Map.merge(&1, functions, fn _key, values1, values2 ->
        insert_new_functions(values1, values2)
      end)
    )
  end

  defp insert_new_functions(functions1, functions2) do
    Enum.reduce(functions2, functions1, fn function, acc ->
      if Enum.member?(acc, function) do
        acc
      else
        [function | acc]
      end
    end)
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

  @spec lookup_functions(t(), name(), predicate :: (SymbolInfo.t() -> boolean())) ::
          [SymbolInfo.t()]
  def lookup_functions(%__MODULE__{enclosing: nil} = context, name, predicate) do
    case Map.fetch(context.functions, name) do
      {:ok, functions} ->
        Enum.filter(functions, predicate)

      :error ->
        []
    end
  end

  def lookup_functions(context, name, predicate) do
    case Map.fetch(context.functions, name) do
      {:ok, functions} ->
        functions = Enum.filter(functions, predicate)

        functions ++
          lookup_functions(
            context.enclosing,
            name,
            &(not Enum.member?(functions, &1) and predicate.(&1))
          )

      :error ->
        lookup_functions(context.enclosing, name, predicate)
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
