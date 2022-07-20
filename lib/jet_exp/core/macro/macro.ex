defmodule JetExp.Core.Macro do
  @moduledoc false

  alias JetExp.Parser.Ast
  alias JetExp.Parser.Context

  @type t() :: module()
  @type name() :: String.t()
  @type errors() :: Keyword.t()

  @callback run(node :: Ast.t(), context :: Context.t()) ::
              {:ok, Ast.t()} | {:error, errors()}

  @doc """
  `expander` is a prewalker to expand macros at compilation time.
  """
  @spec expander(Ast.t(), Context.t()) :: {Ast.t(), Context.t()}
  def expander(node, context) do
    case expand(node, context) do
      {:ok, node} ->
        {node, context}

      {:error, errors} ->
        {Ast.annotate(node, errors: errors), context}

      :skip ->
        {node, context}
    end
  end

  defp expand(node, context) do
    cond do
      Ast.sigil?(node) ->
        expand_sigil(node, context)

      Ast.call?(node) ->
        try_expand(node, context)

      true ->
        :skip
    end
  end

  defp expand_sigil(node, context) do
    with({:ok, macro} <- JetExp.Core.Macro.Sigil.lookup_sigil(context, node)) do
      do_expand(macro, node, context)
    end
  end

  defp try_expand(node, context) do
    name = node |> Ast.call_id() |> Ast.id_name()

    case Context.lookup_macro(context, name) do
      {:ok, macro} ->
        do_expand(macro, node, context)

      :error ->
        :skip
    end
  end

  defp do_expand(macro, node, context) do
    macro.run(node, context)
  end
end
