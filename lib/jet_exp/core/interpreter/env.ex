defmodule JetExp.Core.Interpreter.Env do
  @moduledoc false

  defmodule Function do
    @moduledoc false

    @type opts() :: [require_args: boolean()]

    @type t() :: %__MODULE__{
            module: module(),
            fun: atom(),
            extra_args: [term()],
            opts: opts()
          }

    @enforce_keys [:module, :fun]
    defstruct [
      :module,
      :fun,
      extra_args: [],
      opts: []
    ]

    @default_opts [require_args: true]

    @spec new(module(), fun :: atom(), extra_args :: [term()], opts()) :: t()
    def new(module, fun, extra_args \\ [], opts \\ @default_opts) do
      %__MODULE__{
        module: module,
        fun: fun,
        extra_args: extra_args,
        opts: opts
      }
    end

    @spec apply(t(), args :: [term()]) :: {:ok, term()} | :error
    def apply(%__MODULE__{extra_args: []} = fun, args) do
      Kernel.apply(fun.module, fun.fun, args)
    end

    def apply(%__MODULE__{} = fun, args) do
      Kernel.apply(fun.module, fun.fun, args ++ fun.extra_args)
    end

    @spec require_args?(t()) :: boolean()
    def require_args?(%__MODULE__{} = fun) do
      Keyword.get(fun.opts, :require_args, true)
    end
  end

  @type name() :: String.t()

  @type value() :: nil | boolean() | number() | String.t() | Function.t()

  @typep bindings() :: %{required(name()) => value()}

  @type t() :: %__MODULE__{
          enclosing: nil | t(),
          bindings: bindings()
        }

  @enforce_keys [:bindings]
  defstruct [
    :enclosing,
    :bindings
  ]

  @spec new(bindings()) :: t()
  def new(bindings) do
    %__MODULE__{bindings: bindings}
  end

  @spec new(bindings(), enclosing :: nil | t()) :: t()
  def new(bindings, enclosing) do
    %__MODULE__{bindings: bindings, enclosing: enclosing}
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
end
