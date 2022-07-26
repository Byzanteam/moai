defmodule JetExp.Core.Library.Bool do
  @moduledoc false

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
  """
  @spec bool_and_a([boolean()]) :: {:ok, boolean()}
  def bool_and_a(bools) do
    {:ok, Enum.all?(bools, & &1)}
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
  """
  @spec bool_or_a([boolean()]) :: {:ok, boolean()}
  def bool_or_a(bools) do
    {:ok, Enum.any?(bools, & &1)}
  end
end
