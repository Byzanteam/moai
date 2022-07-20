defmodule JetExp.Parser.Ast do
  @moduledoc false

  @type t() ::
          id_node()
          | nil_node()
          | bool_node()
          | number_node()
          | string_node()
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

  @spec make_id(name(), annotations()) :: id_node()
  def make_id(name, annotations) do
    {:id, annotations, name}
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

  @spec literal?(t()) :: boolean()
  def literal?(node) do
    nil?(node) or bool?(node) or number?(node) or string?(node)
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

  @spec make_list_comp(list_comp_args :: [t(), ...]) :: list_comp_node()
  def make_list_comp(args) do
    {:for, args}
  end

  @spec make_list_comp(list_comp_args :: [t(), ...], annotations()) :: list_comp_node()
  def make_list_comp(args, annotations) do
    {:for, annotations, args}
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

  @spec call_args(call_node()) :: [t()]
  def call_args({_id, args}) do
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

  @spec postwalk(t(), acc, (t(), acc -> {t(), acc})) :: {t, acc} when acc: var
  def postwalk(node, acc, fun) do
    cond do
      atomic?(node) ->
        fun.(node, acc)

      list?(node) ->
        walk_node_with_args(node, &list_args/1, &make_list/1, acc, fun)

      list_comp_binding?(node) ->
        [var, source_expr] = list_comp_binding_args(node)
        {source_expr, acc} = postwalk(source_expr, acc, fun)
        fun.(make_list_comp_binding([var, source_expr]), acc)

      list_comp?(node) ->
        walk_node_with_args(node, &list_comp_args/1, &make_list_comp/1, acc, fun)

      call?(node) ->
        walk_node_with_args(node, &call_args/1, &make_call(call_id(node), &1), acc, fun)

      access_op?(node) ->
        [source_expr, accessor] = op_operands(node)
        {source_expr, acc} = postwalk(source_expr, acc, fun)
        fun.(make_op(op_operator(node), [source_expr, accessor]), acc)

      op?(node) ->
        walk_node_with_args(node, &op_operands/1, &make_op(op_operator(node), &1), acc, fun)
    end
  end

  defp atomic?(node) do
    id?(node) or literal?(node)
  end

  @spec walk_node_with_args(
          t(),
          args_extractor :: (t() -> args :: [t()]),
          builder :: (args :: [t()] -> t()),
          acc :: acc,
          fun :: (t(), acc -> {t(), acc})
        ) :: {t(), acc}
        when acc: var
  defp walk_node_with_args(node, args_extractor, builder, acc, fun) do
    {args, acc} = node |> args_extractor.() |> Enum.map_reduce(acc, &postwalk(&1, &2, fun))
    fun.(builder.(args), acc)
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
