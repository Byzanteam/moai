Nonterminals
  program expr literal group list list_comp call operation
  comma_sep_list call_args_parens
  or_op and_op comp_op rel_op add_op mult_op unary_op dot_op
  .

Terminals
  id nil bool number string sigil
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

list -> '[' ']' : {'[]', []}.
list -> '[' comma_sep_list ']' : {'[]', lists:reverse('$2')}.

list_comp -> 'for' id 'in' expr '->' expr : build_list_comp(build_id('$2'), '$4', '$6').

call -> id call_args_parens : {build_id('$1'), '$2'}.
call_args_parens -> '(' ')' : [].
call_args_parens -> '(' comma_sep_list ')' : lists:reverse('$2').

operation -> expr or_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> expr and_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> expr comp_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> expr rel_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> expr add_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> expr mult_op expr : {build_op('$2'), ['$1', '$3']}.
operation -> unary_op expr : build_unary_op_expr(build_op('$1'), '$2').
operation -> expr dot_op id : {access, ['$1', build_id('$3')]}.

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

build_id({id, _TokenLine, Name}) -> {id, Name}.

build_nil() -> nil.

build_literal({_Category, _TokenLine, Value}) -> Value.

build_sigil({sigil, _TokenLine, Sigil}, Value) -> {sigil, {Sigil, Value}}.

build_op({Op, _TokenLine}) -> Op.

build_unary_op_expr('+', Term) -> Term;
build_unary_op_expr('-', Number) when is_number(Number) -> -Number;
build_unary_op_expr('-', Id) -> {'-', [Id]};
build_unary_op_expr('not', Bool) when is_boolean(Bool) -> not Bool;
build_unary_op_expr('not', Id) -> {'not', [Id]}.

build_list_comp(Bind, SourceExpr, TargetExpr) -> {for, [{in, [Bind, SourceExpr]}, TargetExpr]}.
