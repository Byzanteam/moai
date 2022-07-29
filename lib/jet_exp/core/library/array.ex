defmodule JetExp.Core.Library.Array do
  @moduledoc false

  use JetExp.Core.Library.Builder

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
  @fun_meta {:array_at, signature: []}
end
