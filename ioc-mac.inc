fillto	macro	dest,value
	while	$<dest
	db	value
	endm
	endm

dbh	macro	s
	irpc	char,s
	db	080h+'CHAR'
	endm
	endm
