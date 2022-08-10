defmodule JetExp.Core.Library.Array do
  @moduledoc false

  @__lib_namespace__ "Array"

  Module.register_attribute(__MODULE__, :fun_meta, accumulate: true)

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
  @fun_meta {:at, impl: :array_at, signature: [[{:var, 0}], :number, [{:var, 0}]]}
  @spec array_at([elem], number()) :: {:ok, elem | nil} when elem: var
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
  @fun_meta {:length, impl: :array_length, signature: [[{:var, 0}], :number]}
  @spec array_length([term()]) :: {:ok, non_neg_integer()}
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
  @fun_meta {:contains?,
             impl: :array_contains?,
             signature: [[{:var, 0}], {:var, 0}, :bool],
             opts: [require_args: false]}
  @fun_meta {:contains?,
             impl: :array_contains?,
             signature: [[{:var, 0}], nil, :bool],
             opts: [require_args: false]}
  @spec array_contains?([elem], elem) :: {:ok, boolean() | nil} when elem: var
  def array_contains?(nil, _elem), do: {:ok, nil}

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
  @fun_meta {:subset?, impl: :array_subset?, signature: [[{:var, 0}], [{:var, 0}], [{:var, 0}]]}
  @spec array_subset?(array, array) :: {:ok, boolean()} when array: [term()]
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
  @fun_meta {:disjoint?, impl: :array_disjoint?, signature: [[{:var, 0}], [{:var, 0}], :bool]}
  @spec array_disjoint?(array, array) :: {:ok, boolean()} when array: [term()]
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
  @fun_meta {:concat, impl: :array_concat, signature: [[{:var, 0}], [{:var, 0}], [{:var, 0}]]}
  @spec array_concat(array, array) :: {:ok, array} when array: [term()]
  def array_concat(left, right) do
    {:ok, left ++ right}
  end

  @doc """
  Enumerates the array, removing all duplicated elements.

  ## Examples

    iex> array_uniq([1, 2, 3, nil, nil, 3, 2, 4])
    {:ok, [1, 2, 3, nil, 4]}
  """
  @fun_meta {:uniq, impl: :array_uniq, signature: [[{:var, 0}], [{:var, 0}]]}
  @spec array_uniq(array) :: {:ok, array} when array: [term()]
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
  @fun_meta {:intersection,
             impl: :array_intersection, signature: [[{:var, 0}], [{:var, 0}], [{:var, 0}]]}
  @spec array_intersection(array, array) :: {:ok, array} when array: [term()]
  def array_intersection(array1, array2) do
    {:ok, for(e <- array1, e in array2, do: e)}
  end

  alias JetExp.Parser.Context

  @spec install_symbols(Context.t()) :: Context.t()
  def install_symbols(context) do
    Context.install_functions(context, build_fun_symbols(context))
  end

  defp build_fun_symbols(context) do
    type_aliases = context.type_aliases
    types_and_aliases = JetExp.Typing.Types.BuiltIn.all() ++ Map.keys(type_aliases)

    functions =
      Enum.reduce(@fun_meta, %{}, fn {name, opts}, acc ->
        fun_symbols =
          opts
          |> Keyword.fetch!(:signature)
          |> do_build_fun_symbols(types_and_aliases)

        Map.update(acc, Atom.to_string(name), fun_symbols, &(&1 ++ fun_symbols))
      end)

    %{@__lib_namespace__ => functions}
  end

  defp do_build_fun_symbols(signature, types_and_aliases) do
    var_ids = collect_var_ids(signature)

    for(
      t <- types_and_aliases,
      var_id <- var_ids
    ) do
      Context.SymbolInfo.new(%{type: {:fun, inject_var_type(signature, var_id, t)}})
    end
  end

  defp collect_var_ids(signature) do
    Enum.reduce(signature, MapSet.new(), fn
      {:var, var_id}, acc ->
        MapSet.put(acc, var_id)

      [{:var, var_id}], acc ->
        MapSet.put(acc, var_id)

      _type, acc ->
        acc
    end)
  end

  defp inject_var_type(signature, var_id, t) do
    Enum.map(signature, fn
      {:var, ^var_id} -> t
      [{:var, ^var_id}] -> [t]
      type -> type
    end)
  end

  alias JetExp.Core.Interpreter.Env

  @default_fun_opts [require_args: true]

  @fun_bindings %{
    @__lib_namespace__ =>
      Map.new(@fun_meta, fn {fun_name, meta} ->
        {
          Atom.to_string(fun_name),
          Env.Function.new(
            __MODULE__,
            Keyword.get(meta, :impl, fun_name),
            [],
            Keyword.get(meta, :opts, @default_fun_opts)
          )
        }
      end)
  }

  @spec install_bindings(Env.t()) :: Env.t()
  def install_bindings(env) do
    Env.install_functions(env, @fun_bindings)
  end
end
