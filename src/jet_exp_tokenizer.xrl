Definitions.

ID = [a-zA-Z][0-9a-zA-Z_']*

INT = [0-9]+
FLOAT = [0-9]+\.[0-9]+

STRING = \"(\\.|[^"\\])*\"

WHITESPACE = [\s\t\n\r]

Rules.

for : {token, {'for', TokenLine}}.
in  : {token, {'in', TokenLine}}.
->  : {token, {'->', TokenLine}}.

and : {token, {'and', TokenLine}}.
or  : {token, {'or', TokenLine}}.
not : {token, {'not', TokenLine}}.

nil : {token, {nil, TokenLine}}.

true  : {token, {bool, TokenLine, true}}.
false : {token, {bool, TokenLine, false}}.

{INT} : {token, {number, TokenLine, list_to_integer(TokenChars)}}.
{FLOAT} : {token, {number, TokenLine, list_to_float(TokenChars)}}.

{STRING} : {token, {string, TokenLine, build_string(TokenChars)}}.

{ID} : {token, {id, TokenLine, list_to_binary(TokenChars)}}.

~{ID} : {token, {sigil, TokenLine, list_to_binary(TokenChars)}}.

,  : {token, {',', TokenLine}}.
\( : {token, {'(', TokenLine}}.
\) : {token, {')', TokenLine}}.
\[ : {token, {'[', TokenLine}}.
\] : {token, {']', TokenLine}}.
\. : {token, {'.', TokenLine}}.
\+ : {token, {'+', TokenLine}}.
\- : {token, {'-', TokenLine}}.
\* : {token, {'*', TokenLine}}.
\/ : {token, {'/', TokenLine}}.
== : {token, {'==', TokenLine}}.
!= : {token, {'!=', TokenLine}}.
>  : {token, {'>', TokenLine}}.
<  : {token, {'<', TokenLine}}.
>= : {token, {'>=', TokenLine}}.
<= : {token, {'<=', TokenLine}}.

{WHITESPACE}+ : skip_token.

Erlang code.

build_string(TokenChars) ->
  Binary = list_to_binary(TokenChars),
  trim_string(Binary).

trim_string(<<"\"", BinTail/binary>>) -> trim_string_tail(BinTail).

trim_string_tail(<<"\"">>) -> <<>>;
trim_string_tail(<<C, BinTail/binary>>) ->
  NewBinTail = trim_string_tail(BinTail),
  <<C, NewBinTail/binary>>.
