\ COMMENT  --  set up comments on given column  			11-01-99 20:59:46

in-editor

: trim-dotline
	0 !dotofs
	dotlen dot-tail -trailing nip - 	\ # white spaces to delete
	dotlen over - !dotofs _delete-nchars ;

in-hidden

: past-cmnt-col
	begin   							\ found, past comment col
		col# cmnt-col > 				\ while col# > cmnt-col
		c-left c-char iswhite? and
	while
		delete-char 					\ delete white space
	repeat
	c-right
	col# cmnt-col > if  				\ still > cmnt-col?
		bl insert-char  				\ space before '\
	else
		c-left c-char c-right iswhite? 0= if
			bl insert-char
		then
	then
;

: before-cmnt-col
	begin
		col# cmnt-col < 				\ while col# < cmnt-col
	while
		tab 							\ insert tabs
	repeat
;

in-editor

: fix-comment   						\ force comment to cmnt-col
	read-only? if msg" Can't insert in read-only mode" exit then
	0 !dotofs
	spattern line-buf $move 			\ save spattern
	c" \" spattern $move
	dotln _srch
	line-buf spattern $move 			\ restore spattern
	over dotln = and swap !dotln if 	\ comment already on dot line
		col# 1- 0= if exit then  			\ don't move comments from col 1
		col# cmnt-col >= if 			\ found past cmnt-col
			past-cmnt-col
		else							\ found before cmnt-col
			before-cmnt-col
		then
		c-right
		#cols col# 1- =
		if
			bl insert-char  			\ end of line so insert space
		else
			c-char iswhite? if
				c-right 				\ move past white space
			else
				bl insert-char  		\ insert space between \ and non-space
			then
		then
	else								\ no comment yet
		trim-dotline					\ trim white space from end of line
		col# cmnt-col < if
			before-cmnt-col
		else
			bl insert-char
		then
		[char] \ insert-char bl insert-char \ add the comment
	then
	flagdot ;
