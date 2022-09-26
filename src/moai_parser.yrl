Nonterminals
  program expr literal group list list_comp call operation
  comma_sep_list call_args_parens list_comp_generator
  or_op and_op comp_op rel_op add_op mult_op unary_op dot_op
  .

Terminals
  id namespace nil bool number string sigil
  for in '->' and or not
  ',' '(' ')' '[' ']' '.' '+' '-' '*' '/' '==' '!=' '>' '<' '>=' '<='
  .

Rootsymbol program.

Left     10 or_op.
Left     20 and_op.
Nonassoc 30 comp_op.
Nonassoc 40 rel_op.
Left     50 add_op.
Left     60 mult_op.
Nonassoc 70 unary_op.
Left     80 dot_op.

program -> expr : '$1'.

expr -> id : build_id('$1').
expr -> literal : '$1'.
expr -> group : '$1'.
expr -> list : '$1'.
expr -> list_comp : '$1'.
expr -> call : '$1'.
expr -> operation : '$1'.

literal -> nil : build_nil().
literal -> bool : build_literal('$1').
literal -> number : build_literal('$1').
literal -> string : build_literal('$1').
literal -> sigil literal : build_sigil('$1', '$2').

group -> '(' expr ')' : '$2'.

comma_sep_list -> expr : ['$1'].
comma_sep_list -> comma_sep_list ',' expr : ['$3' | '$1'].

list -> '[' ']' : attach_line({'[]', []}, '$1').
list -> '[' comma_sep_list ']' : attach_line({'[]', lists:reverse('$2')}, '$1').

list_comp -> 'for' list_comp_generator '->' expr : attach_line(build_list_comp('$2', '$4'), '$1').
list_comp_generator -> id 'in' expr : build_list_comp_generator('$1', '$3', [], '$2').
list_comp_generator -> id 'in' expr ',' comma_sep_list : build_list_comp_generator('$1', '$3', '$5', '$2').

call -> namespace dot_op call : attach_namespace_to_call('$3', '$1').
call -> id call_args_parens : attach_line({build_id('$1'), '$2'}, '$1').
call_args_parens -> '(' ')' : [].
call_args_parens -> '(' comma_sep_list ')' : lists:reverse('$2').

operation -> expr or_op expr : build_op('$2', ['$1', '$3']).
operation -> expr and_op expr : build_op('$2', ['$1', '$3']).
operation -> expr comp_op expr : build_op('$2', ['$1', '$3']).
operation -> expr rel_op expr : build_op('$2', ['$1', '$3']).
operation -> expr add_op expr : build_op('$2', ['$1', '$3']).
operation -> expr mult_op expr : build_op('$2', ['$1', '$3']).
operation -> unary_op expr : attach_line(build_unary_op_expr(extract_op('$1'), '$2'), '$1').
operation -> expr dot_op id : build_op('$2', ['$1', build_id('$3')]).

or_op -> 'or' : '$1'.
and_op -> 'and' : '$1'.

comp_op -> '==' : '$1'.
comp_op -> '!=' : '$1'.

rel_op -> '<' : '$1'.
rel_op -> '>' : '$1'.
rel_op -> '<=' : '$1'.
rel_op -> '>=' : '$1'.

add_op -> '+' : '$1'.
add_op -> '-' : '$1'.

mult_op -> '*' : '$1'.
mult_op -> '/' : '$1'.

unary_op -> 'not' : '$1'.
unary_op -> '+' : '$1'.
unary_op -> '-' : '$1'.

dot_op -> '.' : '$1'.

Erlang code.

build_id({id, TokenLine, Name}) -> {id, [{line, TokenLine}], Name}.

build_nil() -> nil.

build_literal({_Category, _TokenLine, Value}) -> Value.

build_sigil({sigil, TokenLine, Sigil}, Value) -> {sigil, [{line, TokenLine}], [Sigil, Value]}.

attach_namespace_to_call({CallId, Meta, CallArgs}, {namespace, _TokenLine, Namespace}) ->
  {CallId, [{context, Namespace} | Meta], CallArgs}.

build_op({Op, TokenLine}, Args) -> {Op, [{line, TokenLine}], Args}.

extract_op({Op, _TokenLine}) -> Op.

build_unary_op_expr('+', Term) -> Term;
build_unary_op_expr('-', Number) when is_number(Number) -> -Number;
build_unary_op_expr('-', Id) -> {'-', [Id]};
build_unary_op_expr('not', Bool) when is_boolean(Bool) -> not Bool;
build_unary_op_expr('not', Id) -> {'not', [Id]}.

build_list_comp(Generator, TargetExpr) -> {for, Generator ++ [TargetExpr]}.

build_list_comp_generator(Id, SourceExpr, Filters, In) ->
  [
   attach_line({in, [build_id(Id), SourceExpr]}, In),
   {filters, [], lists:reverse(Filters)}
  ].

attach_line({Form, Args}, {_Category, TokenLine}) ->
  {Form, [{line, TokenLine}], Args};
attach_line({Form, Args}, {_Category, TokenLine, _Value}) ->
  {Form, [{line, TokenLine}], Args};
attach_line(Node, _Token) -> Node.
