grammar NetworkProtocol;

start
:
	'protocol' name = ID LBRACE vardef+ RBRACE # protocol
;

vardef
:
	name = ID ':' type = VARTYPE
	(
		LPAREN len = NUMBER RPAREN
	)? # variableDef
;

VARTYPE
:
	'int'
	| 'byte'
	| 'char'
	| 'timestamp'
;

ID
:
	[a-zA-Z]+
;

NUMBER
:
	[1-9] [0-9]+
;

LBRACE
:
	'{'
;

RBRACE
:
	'}'
;

LPAREN
:
	'('
;

RPAREN
:
	')'
;

WS
:
	[ \t\r\n]+ -> skip
;