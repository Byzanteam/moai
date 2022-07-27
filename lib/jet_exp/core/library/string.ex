defmodule JetExp.Core.Library.String do
  @moduledoc false

  use JetExp.Core.Library.Builder

  @doc """
  Returns the number of characters in the string.

  ## Examples

    iex> str_length("foobar")
    {:ok, 6}

    iex> str_length("")
    {:ok, 0}
  """
  @fun_meta {:str_length, signature: [:string, :number]}
  @spec str_length(String.t()) :: {:ok, non_neg_integer()}
  def str_length(string) do
    {:ok, String.length(string)}
  end

  @doc """
  Checks if string contains any of the given contents.

  ## Examples

    iex> str_contains?("foobar", "foo")
    {:ok, true}

    iex> str_contains?("foobar", "oof")
    {:ok, false}

    iex> str_contains?("foobar", "")
    {:ok, true}
  """
  @fun_meta {:str_contains?, signature: [:string, :string, :bool]}
  @spec str_contains?(string :: String.t(), contents :: String.t()) :: {:ok, boolean()}
  def str_contains?(string, contents) do
    {:ok, String.contains?(string, contents)}
  end

  @doc """
  Replaces occurrences of pattern in subject with replacement.

  ## Examples

    iex> str_replace("foobar", "foo", "oof")
    {:ok, "oofbar"}

    iex> str_replace("foofoo", "foo", "oof", global: false)
    {:ok, "ooffoo"}

    iex> str_replace("foofoo", "foo", "oof")
    {:ok, "oofoof"}

    iex> str_replace("foobar", "oof", "xxo")
    {:ok, "foobar"}

    iex> str_replace("foobar", "", "x")
    {:ok, "foobar"}
  """
  @fun_meta {:str_replace,
             signature: [:string, :string, :string, :string], extra_args: [[global: false]]}
  @fun_meta {:str_replace_g, impl: :str_replace, signature: [:string, :string, :string, :string]}
  @spec str_replace(
          string :: String.t(),
          pattern :: String.t(),
          replacement :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, String.t()}
  def str_replace(string, pattern, replacement, opts \\ [])

  def str_replace(string, "", _replacement, _opts), do: {:ok, string}

  def str_replace(string, pattern, replacement, opts) do
    {:ok, String.replace(string, pattern, replacement, opts)}
  end

  @doc """
  Divides a string into parts based on a pattern.

  ## Examples

    iex> str_split("foo;bar;", ";")
    {:ok, ["foo", "bar", ""]}

    iex> str_split("foobar;", ";")
    {:ok, ["foobar", ""]}

    iex> str_split(";", ";")
    {:ok, ["", ""]}

    iex> str_split("", ";")
    {:ok, [""]}

    iex> str_split("foobar", "")
    {:ok, ["foobar"]}
  """
  @fun_meta {:str_split, signature: [:string, [:string]]}
  @spec str_split(string :: String.t(), pattern :: String.t()) :: {:ok, [String.t()]}
  def str_split(string, ""), do: {:ok, [string]}

  def str_split(string, pattern) do
    {:ok, String.split(string, pattern)}
  end

  @doc """
  Divides a string into characters.

  ## Examples

    iex> str_chars("foobar")
    {:ok, ["f", "o", "o", "b", "a", "r"]}

    iex> str_chars("")
    {:ok, []}
  """
  @fun_meta {:str_chars, signature: [:string, [:string]]}
  @spec str_chars(String.t()) :: {:ok, [String.t()]}
  def str_chars(string) do
    {:ok, String.graphemes(string)}
  end

  @doc """
  Returns a substring starting at the offset start, and of the given length.

  ## Examples

    iex> str_slice("foobar", 2, 3)
    {:ok, "oba"}

    iex> str_slice("foobar", 2, 10)
    {:ok, "obar"}

    iex> str_slice("foobar", 10, 1)
    {:ok, ""}

    iex> str_slice("foofoo", -1, 2)
    {:ok, nil}

    iex> str_slice("foofoo", 1, -2)
    {:ok, nil}
  """
  @fun_meta {:str_slice, signature: [:string, :number, :number, :string]}
  @spec str_slice(string :: String.t(), start :: non_neg_integer(), length :: non_neg_integer()) ::
          {:ok, String.t() | nil}
  def str_slice(string, start, length) when start >= 0 and length >= 0 do
    {:ok, String.slice(string, start, length)}
  end

  def str_slice(_string, _start, _length), do: {:ok, nil}
end
