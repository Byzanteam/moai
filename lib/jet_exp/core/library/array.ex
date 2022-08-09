defmodule JetExp.Core.Library.Array do
  @moduledoc false

  @doc """
  Find the element at the given index.

  ## Examples

    iex> array_at([1, 2, 3], 1)
    {:ok, 2}

    iex> array_at([1, 2, 3], -1)
    {:ok, nil}

    iex> array_at([1, 2, 3], 10)
    {:ok, nil}

    iex> array_at([1, nil, 3], 1)
    {:ok, nil}
  """
  @spec array_at([elem], number()) :: elem | nil when elem: var
  def array_at([_ | _] = array, index) when is_integer(index) and index >= 0 do
    {:ok, Enum.at(array, index)}
  end

  def array_at(_array, _index) do
    {:ok, nil}
  end

  @doc """
  Returns the length of list.

  ## Examples

    iex> array_length([1, 2, 3])
    {:ok, 3}

    iex> array_length([])
    {:ok, 0}
  """
  @spec array_length([term()]) :: non_neg_integer()
  def array_length(array) do
    {:ok, length(array)}
  end

  @doc """
  Checks if elem exists within the array.

  ## Examples

    iex> array_contains?([1, 2, 3], 1)
    {:ok, true}

    iex> array_contains?([1, nil, 3], nil)
    {:ok, true}

    iex> array_contains?([1, 2, 3], 4)
    {:ok, false}
  """
  @spec array_contains?([elem], elem) :: boolean() when elem: var
  def array_contains?(array, elem) do
    {:ok, Enum.member?(array, elem)}
  end

  @doc """
  Checks if array1's elements are all contained in array2.

  ## Examples

    iex> array_subset?([1, 2], [1, 2, 3])
    {:ok, true}

    iex> array_subset?([1, 4], [1, 2, 3])
    {:ok, false}

    iex> array_subset?([3, 2], [1, 2, 3])
    {:ok, true}

    iex> array_subset?([1, 1, 1], [1, 2, 3])
    {:ok, true}

    iex> array_subset?([1, 1, 1], [1, 1])
    {:ok, true}

    iex> array_subset?([1, nil, nil], [1, 1, nil])
    {:ok, true}

    iex> array_subset?([], [1, 2, 3])
    {:ok, true}

    iex> array_subset?([], [])
    {:ok, true}
  """
  @spec array_subset?(array, array) :: boolean() when array: [term()]
  def array_subset?(array1, array2) do
    {:ok,
     MapSet.subset?(
       MapSet.new(array1),
       MapSet.new(array2)
     )}
  end

  @doc """
  Checks if array1 and array2 have not members in common.

  ## Examples

    iex> array_disjoint?([1, 2], [2, 3])
    {:ok, false}

    iex> array_disjoint?([1, 2], [3, 4])
    {:ok, true}

    iex> array_disjoint?([], [1, 2])
    {:ok, true}

    iex> array_disjoint?([], [])
    {:ok, true}
  """
  @spec array_disjoint?(array, array) :: boolean() when array: [term()]
  def array_disjoint?(array1, array2) do
    {:ok,
     MapSet.disjoint?(
       MapSet.new(array1),
       MapSet.new(array2)
     )}
  end

  @doc """
  Concatenates the array on the right with the array on the left.

  ## Examples

    iex> array_concat([1, 2], [3, 4])
    {:ok, [1, 2, 3, 4]}
  """
  @spec array_concat(array, array) :: array when array: [term()]
  def array_concat(left, right) do
    {:ok, left ++ right}
  end

  @doc """
  Enumerates the array, removing all duplicated elements.

  ## Examples

    iex> array_uniq([1, 2, 3, nil, nil, 3, 2, 4])
    {:ok, [1, 2, 3, nil, 4]}
  """
  @spec array_uniq(array) :: array when array: [term()]
  def array_uniq(array) do
    {:ok, Enum.uniq(array)}
  end

  @doc """
  Returns an array containing only members that array1 and array2
  have in common.

  ## Examples

    iex> array_intersection([1, 2, 2, 3], [1, 2, 4])
    {:ok, [1, 2, 2]}

    iex> array_intersection([1, 2], [3, 4])
    {:ok, []}
  """
  @spec array_intersection(array, array) :: array when array: [term()]
  def array_intersection(array1, array2) do
    {:ok, for(e <- array1, e in array2, do: e)}
  end
end
