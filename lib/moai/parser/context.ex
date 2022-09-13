defmodule Moai.Parser.Context do
  @moduledoc false

  defmodule SymbolInfo do
    @moduledoc false

    @type t() :: %__MODULE__{
            type: Moai.Typing.Types.t() | Moai.Typing.Types.alias()
          }

    @enforce_keys [:type]
    defstruct [:type]

    @spec new(%{
            required(:type) => Moai.Typing.Types.t() | Moai.Typing.Types.alias(),
            optional(term()) => term()
          }) :: t()
    def new(params) do
      %__MODULE__{
        type: Map.fetch!(params, :type)
      }
    end

    @spec extract(t(), :type) :: Moai.Typing.Types.t() | Moai.Typing.Types.alias()
    def extract(%__MODULE__{} = symbol_info, :type) do
      symbol_info.type
    end
  end

  @typep name() :: String.t()
  @typep namespace() :: String.t() | nil

  @typep symbols() :: %{required(name()) => SymbolInfo.t()}
  @typep functions() :: %{required(namespace()) => %{required(name()) => [SymbolInfo.t(), ...]}}
  @typep macros() :: %{required(name()) => Moai.Core.Macro.t()}

  @type type_aliases() :: %{required(Moai.Typing.Types.alias()) => Moai.Typing.Types.t()}

  @type t() :: %__MODULE__{
          enclosing: t() | nil,
          symbols: symbols(),
          functions: functions(),
          macros: macros(),
          type_aliases: type_aliases()
        }

  defstruct [
    :enclosing,
    :symbols,
    :functions,
    :macros,
    type_aliases: %{}
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
      &Map.merge(&1, functions)
    )
  end

  @spec install_macros(t(), macros()) :: t()
  def install_macros(%__MODULE__{} = context, macros) do
    Map.update!(context, :macros, &Map.merge(&1, macros))
  end

  @spec install_type_aliases(t(), type_aliases()) :: t()
  def install_type_aliases(%__MODULE__{} = context, type_aliases) do
    Map.update!(context, :type_aliases, &Map.merge(&1, type_aliases))
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

  @spec lookup_functions(t(), namespace(), name(), predicate :: (SymbolInfo.t() -> boolean())) ::
          [SymbolInfo.t()]
  def lookup_functions(%__MODULE__{enclosing: nil} = context, namespace, name, predicate) do
    with(
      {:ok, functions} <- Map.fetch(context.functions, namespace),
      {:ok, functions} <- Map.fetch(functions, name)
    ) do
      Enum.filter(functions, predicate)
    else
      :error -> []
    end
  end

  def lookup_functions(context, namespace, name, predicate) do
    with(
      {:ok, functions} <- Map.fetch(context.functions, namespace),
      {:ok, functions} <- Map.fetch(functions, name)
    ) do
      functions = Enum.filter(functions, predicate)

      functions ++
        lookup_functions(
          context.enclosing,
          namespace,
          name,
          &(not Enum.member?(functions, &1) and predicate.(&1))
        )
    else
      :error ->
        lookup_functions(context.enclosing, namespace, name, predicate)
    end
  end

  @spec lookup_macro(t(), name()) :: {:ok, Moai.Core.Macro.t()} | :error
  def lookup_macro(%__MODULE__{enclosing: nil} = context, name) do
    Map.fetch(context.macros, name)
  end

  def lookup_macro(%__MODULE__{} = context, name) do
    with(:error <- Map.fetch(context.macros, name)) do
      lookup_macro(context.enclosing, name)
    end
  end

  @spec lookup_type(t(), Moai.Typing.Types.alias()) :: {:ok, Moai.Typing.Types.t()} | :error
  def lookup_type(%__MODULE__{enclosing: nil} = context, name) do
    Map.fetch(context.type_aliases, name)
  end

  def lookup_type(%__MODULE__{} = context, name) do
    with(:error <- Map.fetch(context.type_aliases, name)) do
      lookup_type(context.enclosing, name)
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
