defmodule Moai.Core.Library.String do
  @moduledoc false

  use Moai.Core.Library.Builder, namespace: "String"

  @doc """
  Concatenates two strings.

  ## Examples

    iex> str_concat("foo", "bar")
    {:ok, "foobar"}
  """
  @fun_meta {:concat, impl: :str_concat, signature: [:string, :string, :string]}
  @spec str_concat(String.t(), String.t()) :: {:ok, String.t()}
  def str_concat(string1, string2) do
    {:ok, string1 <> string2}
  end

  @doc """
  Concatenates two strings.

  ## Examples

    iex> str_concat_a(["foo", "bar", "!"])
    {:ok, "foobar!"}

    iex> str_concat_a([])
    {:ok, ""}

    iex> str_concat_a(["foo", "bar", nil])
    {:ok, nil}
  """
  @fun_meta {:concat_, impl: :str_concat, signature: [[:string], :string]}
  @spec str_concat_a([String.t()]) :: {:ok, String.t()}
  def str_concat_a(strings) do
    {:ok, do_str_concat_a(strings, "")}
  end

  defp do_str_concat_a([], acc) do
    acc
  end

  defp do_str_concat_a([nil | _rest], _acc) do
    nil
  end

  defp do_str_concat_a([head | rest], acc) do
    do_str_concat_a(rest, acc <> head)
  end

  @doc """
  Returns the number of characters in the string.

  ## Examples

    iex> str_length("foobar")
    {:ok, 6}

    iex> str_length("魁拔😀")
    {:ok, 3}

    iex> str_length("")
    {:ok, 0}
  """
  @fun_meta {:length, impl: :str_length, signature: [:string, :number]}
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
  @fun_meta {:contains?, impl: :str_contains?, signature: [:string, :string, :bool]}
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
  @fun_meta {:replace,
             impl: :str_replace,
             signature: [:string, :string, :string, :string],
             extra_args: [[global: false]]}
  @fun_meta {:replace_g, impl: :str_replace, signature: [:string, :string, :string, :string]}
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
    {:ok, ["", "f", "o", "o", "b", "a", "r", ""]}
  """
  @fun_meta {:split, impl: :str_split, signature: [:string, [:string]]}
  @spec str_split(string :: String.t(), pattern :: String.t()) :: {:ok, [String.t()]}
  def str_split(string, pattern) do
    {:ok, String.split(string, pattern)}
  end

  @doc """
  Divides a string into characters.

  ## Examples

    iex> str_chars("foobar")
    {:ok, ["f", "o", "o", "b", "a", "r"]}

    iex> str_chars("魁拔😀")
    {:ok, ["魁", "拔", "😀"]}

    iex> str_chars("")
    {:ok, []}
  """
  @fun_meta {:chars, impl: :str_chars, signature: [:string, [:string]]}
  @spec str_chars(String.t()) :: {:ok, [String.t()]}
  def str_chars(string) do
    {:ok, String.graphemes(string)}
  end

  @doc """
  Joins the given string array into a string using joiner as a separator.

  ## Examples

    iex> str_join(["foo", "bar"], ",")
    {:ok, "foo,bar"}

    iex> str_join(["foo"], ",")
    {:ok, "foo"}

    iex> str_join([], ",")
    {:ok, ""}

    iex> str_join(["foo", nil], ",")
    {:ok, nil}
  """
  @fun_meta {:join, impl: :str_join, signature: [[:string], :string, :string]}
  @spec str_join([String.t()], joiner :: String.t()) :: {:ok, String.t() | nil}
  def str_join([], _joiner) do
    {:ok, ""}
  end

  def str_join([str | rest], joiner) do
    {:ok, do_str_join(rest, joiner, str)}

    if is_nil(str) do
      {:ok, nil}
    else
      {:ok, do_str_join(rest, joiner, str)}
    end
  end

  defp do_str_join([], _joiner, acc) do
    acc
  end

  defp do_str_join([nil | _rest], _joiner, _acc) do
    nil
  end

  defp do_str_join([str | rest], joiner, acc) do
    do_str_join(rest, joiner, acc <> joiner <> str)
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
  @fun_meta {:slice, impl: :str_slice, signature: [:string, :number, :number, :string]}
  @spec str_slice(string :: String.t(), start :: non_neg_integer(), length :: non_neg_integer()) ::
          {:ok, String.t() | nil}
  def str_slice(string, start, length) when start >= 0 and length >= 0 do
    {:ok, String.slice(string, start, length)}
  end

  def str_slice(_string, _start, _length), do: {:ok, nil}
end
