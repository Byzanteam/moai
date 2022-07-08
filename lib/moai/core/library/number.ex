defmodule Moai.Core.Library.Number do
  @moduledoc false

  use Moai.Core.Library.Builder, namespace: "Number"

  @doc """
  Sums up all numbers in a list. Returns 0 for empty list.

  ## Examples

    iex> n_sum_a([1, 2, 3])
    {:ok, 6}

    iex> n_sum_a([])
    {:ok, 0}

    iex> n_sum_a([1, 2, nil])
    {:ok, nil}
  """
  @fun_meta {:sum_a, impl: :n_sum_a, signature: [[:number], :number]}
  @spec n_sum_a([number()]) :: {:ok, number()}
  def n_sum_a(numbers) do
    {:ok,
     Enum.reduce_while(numbers, 0, fn
       nil, _acc ->
         {:halt, nil}

       x, acc ->
         {:cont, x + acc}
     end)}
  end

  @doc """
  Multiplies all numbers in a list. Returns 1 for empty list.

  ## Examples

    iex> n_product_a([1, 2, 3])
    {:ok, 6}

    iex> n_product_a([])
    {:ok, 1}

    iex> n_product_a([1, 2, nil])
    {:ok, nil}
  """
  @fun_meta {:product_a, impl: :n_product_a, signature: [[:number], :number]}
  @spec n_product_a([number()]) :: {:ok, number()}
  def n_product_a(numbers) do
    {:ok,
     Enum.reduce_while(numbers, 1, fn
       nil, _acc ->
         {:halt, nil}

       x, acc ->
         {:cont, x * acc}
     end)}
  end

  @doc """
  Truncates floats to integers.

  ## Examples

    iex> n_truncate(1.3)
    {:ok, 1}

    iex> n_truncate(1)
    {:ok, 1}
  """
  @fun_meta {:truncate, impl: :n_truncate, signature: [:number, :number]}
  @spec n_truncate(number()) :: {:ok, integer()}
  def n_truncate(number) do
    {:ok, trunc(number)}
  end

  @doc """
  Rounds a number to an arbitrary number of fractional digits.

  ## Examples

    iex> n_round(3.1415, 0)
    {:ok, 3.0}

    iex> n_round(3.1415, 3)
    {:ok, 3.142}

    iex> n_round(3, 1)
    {:ok, 3}
  """
  @fun_meta {:round, impl: :n_round, signature: [:number, :number]}
  @spec n_round(value :: number(), precision :: non_neg_integer()) :: {:ok, number()}
  def n_round(number, _precision) when is_integer(number), do: {:ok, number}

  def n_round(number, precision) do
    {:ok, Float.round(number, precision)}
  end

  @doc """
  Rounds a float to the largest number less than or equal to num.

  ## Examples

    iex> n_floor(3.1415, 0)
    {:ok, 3.0}

    iex> n_floor(3.1415, 3)
    {:ok, 3.141}

    iex> n_floor(3, 1)
    {:ok, 3}
  """
  @fun_meta {:floor, impl: :floor, signature: [:number, :number]}
  @spec n_floor(value :: number(), precision :: non_neg_integer()) :: {:ok, number()}
  def n_floor(number, _precision) when is_integer(number), do: {:ok, number}

  def n_floor(number, precision) do
    {:ok, Float.floor(number, precision)}
  end

  @doc """
  Rounds a float to the largest number less than or equal to num.

  ## Examples

    iex> n_ceil(3.1415, 0)
    {:ok, 4.0}

    iex> n_ceil(3.1415, 3)
    {:ok, 3.142}

    iex> n_ceil(3, 1)
    {:ok, 3}
  """
  @fun_meta {:ceil, impl: :n_ceil, signature: [:number, :number]}
  @spec n_ceil(value :: number(), precision :: non_neg_integer()) :: {:ok, number()}
  def n_ceil(number, _precision) when is_integer(number), do: {:ok, number}

  def n_ceil(number, precision) do
    {:ok, Float.ceil(number, precision)}
  end

  @doc """
  Parses a binary into a number.

  ## Examples

    iex> n_parse_string("3.1415")
    {:ok, 3.1415}

    iex> n_parse_string("3.0")
    {:ok, 3.0}

    iex> n_parse_string("3")
    {:ok, 3}

    iex> n_parse_string("foobar")
    {:ok, nil}
  """
  @fun_meta {:parse_string, impl: :n_parse_string, signature: [:string, :number]}
  @spec n_parse_string(String.t()) :: {:ok, number() | nil}
  def n_parse_string(string) do
    with(
      :error <- parse_integer(string),
      :error <- parse_float(string)
    ) do
      {:ok, nil}
    end
  end

  defp parse_integer(string) do
    try do
      {:ok, String.to_integer(string)}
    rescue
      ArgumentError ->
        :error
    end
  end

  defp parse_float(string) do
    try do
      {:ok, String.to_float(string)}
    rescue
      ArgumentError ->
        :error
    end
  end

  @doc """
  Converts a number to string.

  ## Examples

    iex> n_to_string(1)
    {:ok, "1"}

    iex> n_to_string(1.1)
    {:ok, "1.1"}
  """
  @fun_meta {:to_string, impl: :n_to_string, signature: [:number, :string]}
  @spec n_to_string(number()) :: {:ok, String.t()}
  def n_to_string(number) do
    {:ok, to_string(number)}
  end
end
