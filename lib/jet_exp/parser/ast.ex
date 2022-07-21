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

  @type name() :: String.t()

  @type id_node() :: {:id, name()} | {:id, annotations(), name()}

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

  @type sigil_node() :: {:sigil, args :: [t()]} | {:sigil, annotations(), args :: [t]}

  @type list_node() :: {:"[]", args :: [t()]} | {:"[]", annotations(), args :: [t()]}

  @type list_comp_node() ::
          {:for, args :: [t(), ...]}
          | {:for, annotations(), args :: [t(), ...]}
  @type list_comp_node_binding() ::
          {:in, list_comp_node_binding_args :: [t(), ...]}
          | {:in, annotations(), list_comp_node_binding_args :: [t(), ...]}

  @type call_node() :: {id_node(), args :: [t()]} | {id_node(), annotations(), args :: [t()]}

  @typep operator() ::
           :+ | :- | :* | :/ | :and | :or | :not | :== | :!= | :< | :> | :<= | :>= | :.
  @type op_node() ::
          {operator(), operands :: [t(), ...]}
          | {operator(), annotations(), operands :: [t(), ...]}

  @typep errors() :: Keyword.t()
  @type annotations() :: [type: JetExp.Typing.Types.t(), errors: errors()]

  @spec id?(t()) :: boolean()
  def id?(node) do
    match?({:id, name} when is_binary(name), node) or
      match?({:id, _annotations, name} when is_binary(name), node)
  end

  @spec id_name(id_node()) :: name()
  def id_name({:id, name}) do
    name
  end

  def id_name({:id, _annotations, name}) do
    name
  end

  @spec make_id(name()) :: id_node()
  def make_id(name) do
    {:id, name}
  end

  @spec make_id(name(), annotations()) :: id_node()
  def make_id(name, annotations) do
    {:id, annotations, name}
  end

  @spec update_id(id_node(), name()) :: id_node()
  def update_id({:id, annotations, _name}, name) do
    {:id, annotations, name}
  end

  def update_id(_node, name) do
    make_id(name)
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
    match?({:sigil, [_ | _]}, node) or match?({:sigil, _annotations, [_ | _]}, node)
  end

  @spec sigil_args(sigil_node()) :: [t()]
  def sigil_args({:sigil, args}) do
    args
  end

  def sigil_args({:sigil, _annotations, args}) do
    args
  end

  @spec make_sigil(args :: [t()]) :: sigil_node()
  def make_sigil(args) do
    {:sigil, args}
  end

  @spec make_sigil(args :: [t()], annotations()) :: sigil_node()
  def make_sigil(args, annotations) do
    {:sigil, annotations, args}
  end

  @spec update_sigil(sigil_node(), args :: [t()]) :: sigil_node()
  def update_sigil({:sigil, annotations, _args}, args) do
    {:sigil, annotations, args}
  end

  def update_sigil(_node, args) do
    make_sigil(args)
  end

  @spec list?(t()) :: boolean()
  def list?(node) do
    match?({:"[]", args} when is_list(args), node) or
      match?({:"[]", _annotations, args} when is_list(args), node)
  end

  @spec list_args(list_node()) :: [t()]
  def list_args({:"[]", args}) do
    args
  end

  def list_args({:"[]", _annotations, args}) do
    args
  end

  @spec make_list(args :: [t()]) :: list_node()
  def make_list(args) do
    {:"[]", args}
  end

  @spec make_list(args :: [t()], annotations()) :: list_node()
  def make_list(args, annotations) do
    {:"[]", annotations, args}
  end

  @spec update_list(list_node(), args :: [t]) :: list_node()
  def update_list({:"[]", annotations, _args}, args) do
    {:"[]", annotations, args}
  end

  def update_list(_node, args) do
    make_list(args)
  end

  @spec list_comp?(t()) :: boolean()
  def list_comp?({:for, [binding, _target_expr]}) do
    list_comp_binding?(binding)
  end

  def list_comp?({:for, _annotations, [binding, _target_expr]}) do
    list_comp_binding?(binding)
  end

  def list_comp?(_node), do: false

  @spec list_comp_args(list_comp_node()) :: [t(), ...]
  def list_comp_args({:for, args}) do
    args
  end

  def list_comp_args({:for, _annotations, args}) do
    args
  end

  @spec list_comp_binding?(t()) :: boolean()
  def list_comp_binding?({:in, [_bind, _source_expr]}) do
    true
  end

  def list_comp_binding?({:in, _annotations, [_bind, _source_expr]}) do
    true
  end

  def list_comp_binding?(_node), do: false

  @spec list_comp_binding(list_comp_node()) :: list_comp_node_binding()
  def list_comp_binding({:for, [binding, _target_expr]}) do
    binding
  end

  def list_comp_binding({:for, _annotations, [binding, _target_expr]}) do
    binding
  end

  @spec list_comp_binding_args(list_comp_node_binding()) :: [t(), ...]
  def list_comp_binding_args({:in, binding_args}) do
    binding_args
  end

  def list_comp_binding_args({:in, _annotations, binding_args}) do
    binding_args
  end

  @spec list_comp_target(list_comp_node()) :: t()
  def list_comp_target({:for, [_binding, target_expr]}) do
    target_expr
  end

  def list_comp_target({:for, _annotations, [_binding, target_expr]}) do
    target_expr
  end

  @spec make_list_comp_binding(list_comp_node_binding_args :: [t(), ...]) ::
          list_comp_node_binding()
  def make_list_comp_binding(binding_args) do
    {:in, binding_args}
  end

  @spec make_list_comp_binding(list_comp_node_binding_args :: [t(), ...], annotations()) ::
          list_comp_node_binding()
  def make_list_comp_binding(binding_args, annotations) do
    {:in, annotations, binding_args}
  end

  @spec update_list_comp_binding(
          list_comp_node_binding(),
          list_comp_node_binding_args :: [t(), ...]
        ) :: list_comp_node_binding()
  def update_list_comp_binding({:in, annotations, _binding_args}, binding_args) do
    {:in, annotations, binding_args}
  end

  def update_list_comp_binding(_node, binding_args) do
    make_list_comp_binding(binding_args)
  end

  @spec make_list_comp(list_comp_args :: [t(), ...]) :: list_comp_node()
  def make_list_comp(args) do
    {:for, args}
  end

  @spec make_list_comp(list_comp_args :: [t(), ...], annotations()) :: list_comp_node()
  def make_list_comp(args, annotations) do
    {:for, annotations, args}
  end

  @spec update_list_comp(list_comp_node(), list_comp_args :: [t(), ...]) :: list_comp_node()
  def update_list_comp({:for, annotations, _args}, args) do
    {:for, annotations, args}
  end

  def update_list_comp(_node, args) do
    make_list_comp(args)
  end

  @spec conditional?(t()) :: boolean()
  def conditional?(node) do
    call?(node) and node |> call_id() |> id_name() === "if" and
      (match?({_id, [_predicate, _consequent]}, node) or
         match?({_id, _annotations, [_predicate, _consequent]}, node) or
         match?({_id, [_predicate, _consequent, _alternative]}, node) or
         match?({_id, _annotations, [_predicate, _consequent, _alternative]}, node))
  end

  @spec conditional_predicate(call_node()) :: t()
  def conditional_predicate({_id, [predicate | _rest]}) do
    predicate
  end

  def conditional_predicate({_id, _annotations, [predicate | _rest]}) do
    predicate
  end

  @spec conditional_consequent(call_node()) :: t()
  def conditional_consequent({_id, [_predicate, consequent | _rest]}) do
    consequent
  end

  def conditional_consequent({_id, _annotations, [_predicate, consequent | _rest]}) do
    consequent
  end

  @spec conditional_alternative(call_node()) :: {:ok, t()} | :error
  def conditional_alternative({_id, [_predicate, _consequent, alternative]}) do
    {:ok, alternative}
  end

  def conditional_alternative({_id, _annotations, [_predicate, _consequent, alternative]}) do
    {:ok, alternative}
  end

  def conditional_alternative({_id, [_predicate, _consequent]}) do
    :error
  end

  @spec call?(t()) :: boolean()
  def call?({id, args}) when is_list(args) do
    id?(id)
  end

  def call?({id, _annotations, args}) when is_list(args) do
    id?(id)
  end

  def call?(_node) do
    false
  end

  @spec call_id(call_node()) :: id_node()
  def call_id({id, _args}) do
    id
  end

  def call_id({id, _annotations, _args}) do
    id
  end

  @spec call_args(call_node()) :: [t()]
  def call_args({_id, args}) do
    args
  end

  def call_args({_id, _annotations, args}) do
    args
  end

  @spec make_call(id_node(), args :: [t()]) :: call_node()
  def make_call(call_id, args) do
    {call_id, args}
  end

  @spec make_call(id_node(), args :: [t()], annotations()) :: call_node()
  def make_call(call_id, args, annotations) do
    {call_id, annotations, args}
  end

  @spec update_call(call_node(), args :: [t()]) :: call_node()
  def update_call({id, annotations, _args}, args) do
    {id, annotations, args}
  end

  def update_call(node, args) do
    make_call(call_id(node), args)
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
        {op, _operands} when op in unquote(ops),
        node
      )
    end
  end

  @spec op?(t()) :: boolean()
  def op?(node) do
    arith_op?(node) or logic_op?(node) or comp_op?(node) or rel_op?(node) or access_op?(node)
  end

  @spec op_operator(op_node()) :: operator()
  def op_operator({op, _operands}) do
    op
  end

  @spec op_operands(op_node()) :: [t()]
  def op_operands({_op, operands}) do
    operands
  end

  @spec make_op(operator(), operands :: [t()]) :: op_node()
  def make_op(operator, operands) do
    {operator, operands}
  end

  @spec make_op(operator(), operands :: [t()], annotations()) :: op_node()
  def make_op(operator, operands, annotations) do
    {operator, annotations, operands}
  end

  @spec update_op(op_node(), operands :: [t()]) :: op_node()
  def update_op({op, annotations, _operands}, operands) do
    {op, annotations, operands}
  end

  def update_op(node, operands) do
    make_op(op_operator(node), operands)
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
          annotations()
        ) ::
          id_node()
          | list_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node()
  def annotate(node, annotations) do
    cond do
      id?(node) ->
        make_id(id_name(node), annotations)

      list?(node) ->
        make_list(list_args(node), annotations)

      sigil?(node) ->
        make_sigil(sigil_args(node), annotations)

      list_comp_binding?(node) ->
        make_list_comp_binding(list_comp_binding_args(node), annotations)

      list_comp?(node) ->
        make_list_comp(list_comp_args(node), annotations)

      call?(node) ->
        call_id = call_id(node)
        args = call_args(node)
        make_call(call_id, args, annotations)

      op?(node) ->
        op = op_operator(node)
        operands = op_operands(node)
        make_op(op, operands, annotations)
    end
  end

  @spec extract_annotation(
          id_node()
          | list_node()
          | sigil_node()
          | list_comp_node()
          | list_comp_node_binding()
          | call_node()
          | op_node(),
          key :: :type | :errors
        ) :: {:ok, JetExp.Typing.Types.t() | errors()} | :error
  def extract_annotation(node, key) do
    {_category, annotations, _args} = node
    Keyword.fetch(annotations, key)
  end
end
