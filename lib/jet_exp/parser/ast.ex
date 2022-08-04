defmodule JetExp.Parser.Ast do
  @moduledoc false

  @type t() ::
          id_node()
          | nil_node()
          | bool_node()
          | number_node()
          | string_node()
          | object_node()
          | sigil_node()
          | list_node()
          | list_comp_node_binding()
          | list_comp_node()
          | call_node()
          | op_node()

  @type errors() :: Keyword.t()
  @type node_meta() :: [{:line, non_neg_integer()} | annotation()]
  @type annotation() ::
          {:type, JetExp.Typing.Types.t() | JetExp.Typing.Types.alias()} | {:errors, errors()}

  @type name() :: String.t()

  @type id_node() :: {:id, node_meta(), name()}

  @type nil_node() :: nil
  @type bool_node() :: boolean()
  @type number_node() :: number()
  @type string_node() :: String.t()

  @type object_value() ::
          nil
          | nil_node()
          | bool_node()
          | number_node()
          | string_node()
          | [object_value()]

  @type object_node() :: %{required(name()) => object_value()}

  @type sigil_node() :: {:sigil, node_meta(), args :: [t]}

  @type list_node() :: {:"[]", node_meta(), args :: [t()]}

  @type list_comp_node() :: {:for, node_meta(), args :: [t(), ...]}
  @type list_comp_node_binding() :: {:in, node_meta(), list_comp_node_binding_args :: [t(), ...]}

  @type call_node() :: {id_node(), node_meta(), args :: [t()]}

  @typep operator() ::
           :+ | :- | :* | :/ | :and | :or | :not | :== | :!= | :< | :> | :<= | :>= | :.
  @type op_node() :: {operator(), node_meta(), operands :: [t(), ...]}

  @spec id?(t()) :: boolean()
  def id?(node) do
    match?({:id, _node_meta, name} when is_binary(name), node)
  end

  @spec id_name(id_node()) :: name()
  def id_name({:id, _node_meta, name}) do
    name
  end

  @spec make_id(name(), node_meta()) :: id_node()
  def make_id(name, node_meta) do
    {:id, node_meta, name}
  end

  @spec update_id(id_node(), name()) :: id_node()
  def update_id({:id, node_meta, _name}, name) do
    {:id, node_meta, name}
  end

  @spec nil?(t()) :: boolean()
  def nil?(node) do
    is_nil(node)
  end

  @spec bool?(t()) :: boolean()
  def bool?(node) do
    is_boolean(node)
  end

  @spec number?(t()) :: boolean()
  def number?(node) do
    is_number(node)
  end

  @spec string?(t()) :: boolean()
  def string?(node) do
    is_binary(node)
  end

  @spec object?(t()) :: boolean()
  def object?(node) do
    is_map(node)
  end

  @spec literal?(t()) :: boolean()
  def literal?(node) do
    nil?(node) or bool?(node) or number?(node) or string?(node) or object?(node)
  end

  @spec sigil?(t()) :: boolean()
  def sigil?(node) do
    match?({:sigil, _node_meta, [_ | _]}, node)
  end

  @spec sigil_args(sigil_node()) :: [t()]
  def sigil_args({:sigil, _node_meta, args}) do
    args
  end

  @spec make_sigil(args :: [t()], node_meta()) :: sigil_node()
  def make_sigil(args, node_meta) do
    {:sigil, node_meta, args}
  end

  @spec update_sigil(sigil_node(), args :: [t()]) :: sigil_node()
  def update_sigil({:sigil, node_meta, _args}, args) do
    {:sigil, node_meta, args}
  end

  @spec list?(t()) :: boolean()
  def list?(node) do
    match?({:"[]", _node_meta, args} when is_list(args), node)
  end

  @spec list_args(list_node()) :: [t()]
  def list_args({:"[]", _node_meta, args}) do
    args
  end

  @spec make_list(args :: [t()], node_meta()) :: list_node()
  def make_list(args, node_meta) do
    {:"[]", node_meta, args}
  end

  @spec update_list(list_node(), args :: [t]) :: list_node()
  def update_list({:"[]", node_meta, _args}, args) do
    {:"[]", node_meta, args}
  end

  @spec list_comp?(t()) :: boolean()
  def list_comp?({:for, _node_meta, [binding, _target_expr]}) do
    list_comp_binding?(binding)
  end

  def list_comp?(_node), do: false

  @spec list_comp_args(list_comp_node()) :: [t(), ...]
  def list_comp_args({:for, _node_meta, args}) do
    args
  end

  @spec list_comp_binding?(t()) :: boolean()
  def list_comp_binding?({:in, [_bind, _source_expr]}) do
    true
  end

  def list_comp_binding?({:in, _node_meta, [_bind, _source_expr]}) do
    true
  end

  def list_comp_binding?(_node), do: false

  @spec list_comp_binding(list_comp_node()) :: list_comp_node_binding()
  def list_comp_binding({:for, _node_meta, [binding, _target_expr]}) do
    binding
  end

  @spec list_comp_binding_args(list_comp_node_binding()) :: [t(), ...]
  def list_comp_binding_args({:in, _node_meta, binding_args}) do
    binding_args
  end

  @spec list_comp_target(list_comp_node()) :: t()
  def list_comp_target({:for, _node_meta, [_binding, target_expr]}) do
    target_expr
  end

  @spec make_list_comp_binding(list_comp_node_binding_args :: [t(), ...], node_meta()) ::
          list_comp_node_binding()
  def make_list_comp_binding(binding_args, node_meta) do
    {:in, node_meta, binding_args}
  end

  @spec update_list_comp_binding(
          list_comp_node_binding(),
          list_comp_node_binding_args :: [t(), ...]
        ) :: list_comp_node_binding()
  def update_list_comp_binding({:in, node_meta, _binding_args}, binding_args) do
    {:in, node_meta, binding_args}
  end

  @spec make_list_comp(list_comp_args :: [t(), ...], node_meta()) :: list_comp_node()
  def make_list_comp(args, node_meta) do
    {:for, node_meta, args}
  end

  @spec update_list_comp(list_comp_node(), list_comp_args :: [t(), ...]) :: list_comp_node()
  def update_list_comp({:for, node_meta, _args}, args) do
    {:for, node_meta, args}
  end

  @spec conditional?(t()) :: boolean()
  def conditional?(node) do
    call?(node) and node |> call_id() |> id_name() === "if" and
      (match?({_id, _node_meta, [_predicate, _consequent]}, node) or
         match?({_id, _node_meta, [_predicate, _consequent, _alternative]}, node))
  end

  @spec conditional_predicate(call_node()) :: t()
  def conditional_predicate({_id, _node_meta, [predicate | _rest]}) do
    predicate
  end

  @spec conditional_consequent(call_node()) :: t()
  def conditional_consequent({_id, _node_meta, [_predicate, consequent | _rest]}) do
    consequent
  end

  @spec conditional_alternative(call_node()) :: {:ok, t()} | :error
  def conditional_alternative({_id, _node_meta, [_predicate, _consequent, alternative]}) do
    {:ok, alternative}
  end

  def conditional_alternative({_id, _node_meta, [_predicate, _consequent]}) do
    :error
  end

  @spec call?(t()) :: boolean()
  def call?({id, _node_meta, args}) when is_list(args) do
    id?(id)
  end

  def call?(_node) do
    false
  end

  @spec call_id(call_node()) :: id_node()
  def call_id({id, _node_meta, _args}) do
    id
  end

  @spec call_args(call_node()) :: [t()]
  def call_args({_id, _node_meta, args}) do
    args
  end

  @spec make_call(id_node(), args :: [t()], node_meta()) :: call_node()
  def make_call(call_id, args, node_meta) do
    {call_id, node_meta, args}
  end

  @spec update_call(call_node(), args :: [t()]) :: call_node()
  def update_call({id, node_meta, _args}, args) do
    {id, node_meta, args}
  end

  @ops %{
    arith: [:+, :-, :*, :/],
    logic: [:and, :or, :not],
    comp: [:==, :!=],
    rel: [:<, :>, :<=, :>=],
    access: [:.]
  }

  for {category, ops} <- @ops do
    fun = :"#{category}_op?"

    @spec unquote(fun)(t()) :: boolean()
    def unquote(fun)(node) do
      match?(
        {op, _node_meta, _operands} when op in unquote(ops),
        node
      )
    end
  end

  @spec op?(t()) :: boolean()
  def op?(node) do
    arith_op?(node) or logic_op?(node) or comp_op?(node) or rel_op?(node) or access_op?(node)
  end

  @spec op_operator(op_node()) :: operator()
  def op_operator({op, _node_meta, _operands}) do
    op
  end

  @spec op_operands(op_node()) :: [t()]
  def op_operands({_op, _node_meta, operands}) do
    operands
  end

  @spec make_op(operator(), operands :: [t()], node_meta()) :: op_node()
  def make_op(operator, operands, node_meta) do
    {operator, node_meta, operands}
  end

  @spec update_op(op_node(), operands :: [t()]) :: op_node()
  def update_op({op, node_meta, _operands}, operands) do
    {op, node_meta, operands}
  end

  defp atomic?(node) do
    id?(node) or literal?(node)
  end

  @spec traverse(t(), acc, pre :: fun, post :: fun) :: {t(), acc}
        when fun: (t(), acc -> {t(), acc}), acc: var
  def traverse(node, acc, pre, post) do
    {node, acc} = pre.(node, acc)
    do_traverse(node, acc, pre, post)
  end

  defp do_traverse(node, acc, pre, post) do
    cond do
      atomic?(node) ->
        post.(node, acc)

      list?(node) ->
        {list_args, acc} = node |> list_args() |> do_traverse_args(acc, pre, post)
        post.(update_list(node, list_args), acc)

      sigil?(node) ->
        {args, acc} = node |> sigil_args() |> do_traverse_args(acc, pre, post)
        post.(update_sigil(node, args), acc)

      list_comp_binding?(node) ->
        [var, source_expr] = list_comp_binding_args(node)
        {source_expr, acc} = pre.(source_expr, acc)
        {source_expr, acc} = do_traverse(source_expr, acc, pre, post)
        post.(update_list_comp_binding(node, [var, source_expr]), acc)

      list_comp?(node) ->
        {args, acc} = node |> list_comp_args() |> do_traverse_args(acc, pre, post)
        post.(update_list_comp(node, args), acc)

      call?(node) ->
        {args, acc} = node |> call_args() |> do_traverse_args(acc, pre, post)
        post.(update_call(node, args), acc)

      access_op?(node) ->
        [source_expr, accessor] = op_operands(node)
        {source_expr, acc} = pre.(source_expr, acc)
        {source_expr, acc} = do_traverse(source_expr, acc, pre, post)
        post.(update_op(node, [source_expr, accessor]), acc)

      op?(node) ->
        {operands, acc} = node |> op_operands() |> do_traverse_args(acc, pre, post)
        post.(update_op(node, operands), acc)
    end
  end

  defp do_traverse_args(args, acc, pre, post) do
    Enum.map_reduce(args, acc, fn n, acc ->
      {n, acc} = pre.(n, acc)
      do_traverse(n, acc, pre, post)
    end)
  end

  @spec postwalk(t(), acc, (t(), acc -> {t(), acc})) :: {t, acc} when acc: var
  def postwalk(node, acc, fun) do
    traverse(node, acc, fn x, a -> {x, a} end, fun)
  end

  @spec prewalk(t(), acc, (t(), acc -> {t(), acc})) :: {t, acc} when acc: var
  def prewalk(node, acc, fun) do
    traverse(node, acc, fun, fn x, a -> {x, a} end)
  end

  @spec annotate(
          id_node()
          | list_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node(),
          node_meta()
        ) ::
          id_node()
          | list_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node()
  def annotate(node, node_meta) do
    cond do
      id?(node) ->
        make_id(id_name(node), node_meta)

      list?(node) ->
        make_list(list_args(node), node_meta)

      sigil?(node) ->
        make_sigil(sigil_args(node), node_meta)

      list_comp_binding?(node) ->
        make_list_comp_binding(list_comp_binding_args(node), node_meta)

      list_comp?(node) ->
        make_list_comp(list_comp_args(node), node_meta)

      call?(node) ->
        call_id = call_id(node)
        args = call_args(node)
        make_call(call_id, args, node_meta)

      op?(node) ->
        op = op_operator(node)
        operands = op_operands(node)
        make_op(op, operands, node_meta)
    end
  end

  @spec update_meta(
          id_node()
          | list_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node(),
          key :: :type | :errors,
          value :: JetExp.Typing.Types.t() | JetExp.Typing.Types.alias() | errors()
        ) ::
          id_node()
          | list_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node()
  def update_meta({form, meta, args}, key, value) do
    {form, Keyword.put(meta, key, value), args}
  end

  @spec extract_meta(
          id_node()
          | list_node()
          | sigil_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node(),
          key :: :type | :errors | :line
        ) ::
          {:ok,
           JetExp.Typing.Types.t() | JetExp.Typing.Types.alias() | errors() | non_neg_integer()}
          | :error
  def extract_meta(node, key) do
    {_category, node_meta, _args} = node
    Keyword.fetch(node_meta, key)
  end

  @spec extract_meta!(
          id_node()
          | list_node()
          | sigil_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node(),
          key :: :type | :errors | :line
        ) ::
          JetExp.Typing.Types.t() | JetExp.Typing.Types.alias() | errors() | non_neg_integer()
  def extract_meta!(node, key) do
    {_category, node_meta, _args} = node
    Keyword.fetch!(node_meta, key)
  end
end
