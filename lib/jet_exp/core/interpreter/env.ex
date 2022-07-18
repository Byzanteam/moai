defmodule JetExp.Core.Interpreter.Env do
  @moduledoc false

  @type name() :: String.t()

  @type value() :: nil | boolean() | number() | String.t() | fun_v()
  @type fun_v() :: {module(), function :: atom(), extra_args :: [term()]}

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
