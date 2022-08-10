defmodule JetExp.Core.Library.Bool do
  @moduledoc false

  use JetExp.Core.Library.Builder, namespace: "Bool"

  @doc """
  Returns true if all elements of the list is true, otherwise false.
  Returns true for empty list.

  ## Examples

    iex> bool_and_a([true, true, true])
    {:ok, true}

    iex> bool_and_a([true, false, true])
    {:ok, false}

    iex> bool_and_a([])
    {:ok, true}

    iex> bool_and_a([false, nil])
    {:ok, false}

    iex> bool_and_a([nil, true, true])
    {:ok, nil}
  """
  @fun_meta {:and_a, impl: :bool_and_a, signature: [[:bool], :bool]}
  @spec bool_and_a([boolean()]) :: {:ok, boolean()}
  def bool_and_a(bools) do
    {:ok, do_bool_and_a(bools)}
  end

  defp do_bool_and_a([]) do
    true
  end

  defp do_bool_and_a([nil | _rest]) do
    nil
  end

  defp do_bool_and_a([false | _rest]) do
    false
  end

  defp do_bool_and_a([true | rest]) do
    do_bool_and_a(rest)
  end

  @doc """
  Returns true if any elements of the list is true, otherwise false.

  ## Examples

    iex> bool_or_a([true, false, true])
    {:ok, true}

    iex> bool_or_a([false, false, false])
    {:ok, false}

    iex> bool_or_a([])
    {:ok, false}

    iex> bool_or_a([true, false, nil])
    {:ok, true}

    iex> bool_or_a([nil, true])
    {:ok, nil}
  """
  @fun_meta {:or_a, impl: :bool_or_a, signature: [[:bool], :bool]}
  @spec bool_or_a([boolean()]) :: {:ok, boolean()}
  def bool_or_a(bools) do
    {:ok, do_bool_or_a(bools)}
  end

  defp do_bool_or_a([]) do
    false
  end

  defp do_bool_or_a([nil | _rest]) do
    nil
  end

  defp do_bool_or_a([true | _rest]) do
    true
  end

  defp do_bool_or_a([false | rest]) do
    do_bool_or_a(rest)
  end
end
