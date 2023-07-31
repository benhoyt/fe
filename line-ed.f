\ LINE-ED  --  Line editing routines						11-01-99 21:00:36

in-hidden

defer ed-ekey  ' ekey is ed-ekey		\ allow changing later

: ed-key  ( -- char )   			\ wait for one normal key (not function key)
	0 begin
		drop ed-ekey ekey>char
	until ;

: get-key ( -- 0 | func -1 | key 1 )	\ process multiple key input
	clear-keys
	begin
		ed-ekey add-key 				\ add key to end of inkeys
		findkey ?dup if
			-1 = if 					\ full match?
				-1 exit
			else
				drop					\ no, so loop again
			then
		else
			#keys 1 = if				\ not bound, so check only one key?
				1 thkey ekey>char
				over bl >= and if
					1 exit
				else
					drop
				then
			then
			0 exit  					\ invalid key sequence
		then
	again
;

false value line-done   				\ line exit flag
false value line-esc					\ line escape flag
true value first-char
variable kcurs  kcurs off   			\ position of cursor in key buffer
0 value kbuf-len						\ max length of key buffer
variable kcnt  kcnt off 				\ # of keys currently in key buffer
0 value kbuf							\ pointer to key buffer

create dest-bs 8 c, bl c, 8 c,

: cur-left 8 emit ;
: del-left dest-bs 3 type ;

: dsp-to-eol							\ display to eol leaving cursor at end
	kcnt @ kcurs @ ?do
		kbuf i + c@ emit
	loop ;

: ncur-left ( n -- )					\ move cursor n left
	0 ?do cur-left loop ;
: cur-from-eol
	kcnt @ kcurs @ - ncur-left ;

: buf-open  							\ open a space for a char
	kbuf kcurs @ +  					\ src
	dup 1+  							\ dest
	kcnt @ kcurs @ -					\ count
	move ;

: ch-in ( key - )   					\ insert the key at kcurs in buf
	kcnt @ kbuf-len < 0= if   			\ line still short enough?
		drop exit
	then
	buf-open							\ open a space for a char
	dup emit kbuf kcurs @ + c!  		\ emit and store char
	1 kcurs +!  1 kcnt +!
	dsp-to-eol cur-from-eol ;

in-editor

: l-delete-eol  						\ delete from cursor to end of line
	kcurs @ kcnt @ < if
		kcnt @ kcurs @ ?do bl emit loop
		cur-from-eol
		kcurs @ kcnt !
	then ;

: l-delete-char 						\ delete 1 char
	kcurs @ kcnt @ < if
		-1 kcnt +!
		kbuf kcurs @ + 1+   			\ src
		dup 1-  						\ dest
		kcnt @ kcurs @ -				\ count
		cmove
		dsp-to-eol bl emit
		cur-left cur-from-eol
	then ;

: l-bol 								\ cursor to beginning of line
	kcurs @ ncur-left
	kcurs off ;

: l-eol 								\ cursor to end of line
	dsp-to-eol  kcnt @ kcurs ! ;

: l-left								\ cursor left
	kcurs @ if
		-1 kcurs +!
		cur-left
	then ;

: l-delete-left 						\ do backspace
	kcurs @ if
		l-left
		l-delete-char
	then ;

: l-right   							\ cursor right
	kcurs @ kcnt @ < if
		kbuf kcurs @ + c@ emit  		\ advance cursor
		1 kcurs +!
	then ;

: l-enter   							\ end input
	true to line-done ;

: l-esc 								\ escape from input
	true to line-esc l-enter ;

: l-stuff   							\ stuff next char including ctrl keys
	ed-key ch-in ;

in-hidden

: _accept ( c-addr +n1 -- +n2 ) 		\ receive a line from keyboard
	to kbuf-len 						\ max length
	to kbuf
	kcurs off   						\ cursor at end of field
	true to first-char
	false to line-esc
	false to line-done
	dsp-to-eol cur-from-eol
	begin   							\ new interp loop for key input
		get-key ?dup if 	( func -1 | key 1 )
			-1 = if
				execute
				line-done if
					line-esc if 0 else kcnt @ then
					exit
				then
			else
				first-char if
					kcurs off
					l-delete-eol
				then
				ch-in   				\ insert key
			then
			false to first-char
		then
	again
;

: l-accept ( c-addr +n1 -- +n2 )		\ input a line, max length +n1
	kcnt off _accept ;

: l-edit ( c-addr +n1 +n2 -- +n3 )  	\ edit a line with +n2 bytes in it
	kcnt ! _accept ;
