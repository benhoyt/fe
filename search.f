\ SEARCH  --  search routines   							11-01-99 21:00:24

in-hidden

\ need whole word search
\ Ctrl-\ at start of search pattern means beginning of line
\   at end of search pattern means end of line
\   use stuff-char [ Ctrl-V ] to insert Ctrl-\

0 value search-type 					\ 0=normal, 1=beg, 2=end, 3=beg...end
										\ 4 + above for case sensitive
create spattern 0 c, 60 allot   		\ string to hold search pattern
create rpattern 0 c, 60 allot   		\ string to hold replace pattern

: get-pattern ( str msg -- )
	(msg")  	( str )
	dup count dup ed-#tib ! ed-tib swap move
	+linein 			( str )
	line-esc if drop exit then
	ed-tib ed-#tib @ rot place ;

: get-spattern
	spattern c" Search pattern: "
	get-pattern ;

: set-search-type
	spattern c@ if
		spattern 1+ c@ 28 = 			\ Ctrl-\ at beginning of line
		spattern count + 1- c@ 28 = 2*  \ Ctrl-\ at end of line
		+ negate search-type + to search-type
	then ;

: get-rpattern
	rpattern c" Replace pattern: "
	get-pattern ;

: srch-line ( -- flag )
	dot-tail spattern count search if
		drop dotlp - !dotofs true
	else
		2drop false
	then ;

: beg-srch-line ( -- flag )
	dotofs if false exit then
	dotlen spattern c@ 1- < if false exit then
	dotlp spattern count 1 /string tuck compare 0= ;

: srch-line-end ( -- flag )
	dot-#toeol spattern c@ 1- < if false exit then
	spattern count 1- dot-tail + over dup negate under+
	over >r compare if
		r> drop false
	else
		r> dotlp - !dotofs true
	then ;

: beg-srch-line-end ( -- flag )
	dotofs if false exit then
	spattern c@ 2- dotlen <> if false exit then
	spattern count 1- 1 /string dot-tail compare 0= ;

: isrch-line ( -- flag )
	dot-tail spattern count isearch if
		drop dotlp - !dotofs true
	else
		2drop false
	then ;

: beg-isrch-line ( -- flag )
	dotofs if false exit then
	dotlen spattern c@ 1- < if false exit then
	dotlp spattern count 1 /string tuck icompare 0= ;

: isrch-line-end ( -- flag )
	dot-#toeol spattern c@ 1- < if false exit then
	spattern count 1- dot-tail + over dup negate under+
	over >r icompare if
		r> drop false
	else
		r> dotlp - !dotofs true
	then ;

: beg-isrch-line-end ( -- flag )
	dotofs if false exit then
	spattern c@ 2- dotlen <> if false exit then
	spattern count 1- 1 /string dot-tail icompare 0= ;

create searches
	' isrch-line , ' beg-isrch-line , ' isrch-line-end , ' beg-isrch-line-end ,
	' srch-line , ' beg-srch-line , ' srch-line-end , ' beg-srch-line-end ,

\ search current line for spattern, set dotofs if found
: _srch-line ( -- flag )
	search-type cells searches + @ execute ;

\ search to eob for spattern beginning at dot, if found set dot
: _srch ( -- flag )
	dotln dotofs	  ( dotln dotofs )  \ save dot
	begin
		dotln #lines <  				\ end of buffer?
	while
		_srch-line if
			2drop true exit
		then
		0 !dotofs   					\ start of next line
		dotln 1+ !dotln
	repeat
	!dotofs !dotln false ;

: no-pat
	msg" No pattern" bell ;

in-editor

: ksearch-again 						\ search for previous pattern
	spattern c@ 0= if no-pat exit then
	c-right _srch 0= if c-left msg" Not found" bell then
	?middle flagwindow ;

in-hidden

: _ksearch  							\ search to end of buffer
	get-spattern set-search-type
	line-esc 0= if
		ksearch-again
	then ;

in-editor

: ksearch   							\ case sensitive search to end of buffer
	4 to search-type  _ksearch ;

: kisearch  						 \ case insensitive search to end of buffer
	0 to search-type  _ksearch ;

in-hidden

: do-replace
	read-only? if msg" Can't replace in read-only mode" exit then
	spattern c@ delchars
	rpattern count ins-string
	set-modified ;  					\ buffer changed

: rcount-msg ( rcount - )
	msg" " . ." replacements made" ;

in-editor

: kreplace  							\ replace to end of buffer
	get-spattern set-search-type
	line-esc if exit then
	spattern c@ 0= if no-pat exit then
	get-rpattern
	line-esc if exit then
	0
	begin
		_srch
	while
		do-replace 1+   				\ replace and count
	repeat
	rcount-msg
	?middle flagwindow ;

: kquery-replace
	get-spattern set-search-type
	line-esc if exit then
	spattern c@ 0= if no-pat exit then
	get-rpattern
	line-esc if exit then
	0
	begin
		_srch
	while
		markln >r dotln !markln 		\ show with highlighting on
		markofs >r dotofs spattern c@ + !markofs
		b.flags @ >r
		show-marked
		?middle flagwindow display
		r> b.flags !
		r> !markofs
		r> !markln
		msg" Replace? (Y/N/Esc) "
		key toupper dup [char] Y = if
			drop do-replace 1+  		\ replace and count
		else
			27 = if 					\ Esc
				flagwindow rcount-msg exit
			else
				c-right
			then
		then
	repeat
	rcount-msg flagwindow ;
