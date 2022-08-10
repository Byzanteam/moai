defmodule JetExp.Core.Interpreter.Env do
  @moduledoc false

  defmodule Function do
    @moduledoc false

    @type opts() :: [require_args: boolean()]

    @type t() :: %__MODULE__{
            module: module(),
            fun: atom(),
            extra_args: [term()],
            require_args: boolean()
          }

    @enforce_keys [:module, :fun]
    defstruct [
      :module,
      :fun,
      :require_args,
      extra_args: []
    ]

    @spec new(module(), fun :: atom(), extra_args :: [term()], opts()) :: t()
    def new(module, fun, extra_args \\ [], opts \\ []) do
      require_args = Keyword.get(opts, :require_args, true)

      %__MODULE__{
        module: module,
        fun: fun,
        extra_args: extra_args,
        require_args: require_args
      }
    end

    @spec apply(t(), args :: [term()]) :: {:ok, term()} | :error
    def apply(%__MODULE__{extra_args: []} = fun, args) do
      Kernel.apply(fun.module, fun.fun, args)
    end

    def apply(%__MODULE__{} = fun, args) do
      Kernel.apply(fun.module, fun.fun, args ++ fun.extra_args)
    end
  end

  @type name() :: String.t()
  @typep namespace() :: String.t() | nil

  @type value() ::
          nil
          | boolean()
          | number()
          | String.t()
          | [value()]
          | %{required(name()) => value()}

  @typep bindings() :: %{required(name()) => value()}
  @typep functions() :: %{required(namespace()) => %{required(name()) => Function.t()}}

  @type t() :: %__MODULE__{
          enclosing: nil | t(),
          bindings: bindings(),
          functions: functions()
        }

  @enforce_keys [:bindings, :functions]
  defstruct [
    :enclosing,
    :bindings,
    :functions
  ]

  @typep new_params() :: [bindings: bindings(), functions: functions()]

  @spec new(new_params()) :: t()
  def new(params) do
    bindings = Keyword.get(params, :bindings, %{})
    functions = Keyword.get(params, :functions, %{})

    %__MODULE__{
      bindings: bindings,
      functions: functions
    }
  end

  @spec new(new_params(), enclosing :: nil | t()) :: t()
  def new(new_params, enclosing) do
    %{new(new_params) | enclosing: enclosing}
  end

  @spec lookup(t(), name()) :: {:ok, value()} | :error
  def lookup(%__MODULE__{enclosing: nil} = env, name) do
    Map.fetch(env.bindings, name)
  end

  def lookup(%__MODULE__{} = env, name) do
    with(:error <- Map.fetch(env.bindings, name)) do
      lookup(env.enclosing, name)
    end
  end

  @spec lookup_function(t(), namespace(), name()) :: {:ok, Function.t()} | :error
  def lookup_function(%__MODULE__{enclosing: nil} = env, namespace, name) do
    with({:ok, functions} <- Map.fetch(env.functions, namespace)) do
      Map.fetch(functions, name)
    end
  end

  def lookup_function(%__MODULE__{} = env, namespace, name) do
    with(
      {:ok, functions} <- Map.fetch(env.functions, namespace),
      {:ok, function} <- Map.fetch(functions, name)
    ) do
      {:ok, function}
    else
      :error -> lookup_function(env.enclosing, namespace, name)
    end
  end

  @spec install_bindings(t(), bindings()) :: t()
  def install_bindings(%__MODULE__{} = env, bindings) do
    Map.update!(env, :bindings, &Map.merge(&1, bindings))
  end

  @spec install_functions(t(), functions()) :: t()
  def install_functions(%__MODULE__{} = env, functions) do
    Map.update!(env, :functions, &Map.merge(&1, functions))
  end
end
