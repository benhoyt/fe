\ WRAP  --  word wrap for editor							04-04-99 20:41:52

\ If auto-word-wrap is on, automatically wrap from cursor to end of paragraph
\ If a word is too large to fit on a line, it is cut

in-hidden

: trimmed-len ( n -- len )  			\ length of nth line
	nth-str -trailing nip ;

: trim-dot-line 						\ trim it and move to eol
	dotln trimmed-len !dotofs
	dot-#toeol delete-chars ;

: last-para-line? ( -- flag )   		\ last line in paragraph?
	dotln trimmed-len 0=
	dotln #lines = or if
		true
	else
		dotln 1+ trimmed-len 0=
	then ;

: make-long ( -- flag ) 				\ make this line long by joining next
	begin   							\ line(s) in paragraph; true if long
		trim-dot-line
		dotofs r-margin <=
	while
		last-para-line? if false exit then
		\ join next line
		bl insert-char
		c-right c-char bl = if
			delete-word 				\ delete space at beginning of next line
		then
		c-left delete-char  			\ join lines
	repeat
	true ;

: wrap-location 						\ works only if space at eol
	r-margin !dotofs c-char bl = if
		c-word-right
	else
		dotofs dup 1- !dotofs c-char bl <> swap !dotofs if
			c-word-left
		then
	then ;

: wrap-line 						   \ wrap line, cursor to next line
	false to save-deleted?
	\ make this line longer than right margin
	make-long 0= if
		-1 to prevcol
		c-bol c-down
		true to save-deleted?
		exit
	then
	wrap-location dotofs 0= if			\ word too long for line?
		r-margin !dotofs bl insert-char
	then
	split-line c-right ;

: ljust-line							\ justify line to left margin
	dotlen if
		c-char bl = if
			delete-word
		then
		bl l-margin insert-chars
	then ;

: next-para								\ move to next paragraph
	begin
		dotln #lines <>
		dotln trimmed-len 0= and
	while
		trim-dot-line
		c-right
	repeat ;

: wrap-rest 							\ wrap rest paragraph
	begin   							\  don't touch left end of current line
		dotln trimmed-len
	while
		wrap-line
		ljust-line
	repeat
	next-para flageow ;

: nowrap-msg
	msg" Can't wrap in read only mode" ;

in-editor

: word-wrap 							\ wrap from cursor to end of paragraph
	read-only? if nowrap-msg exit then
	wrap-rest ;

: left-justify  						\ left justify current line and rest
	read-only? if nowrap-msg exit then 	\ of paragraph
	0 !dotofs  ljust-line wrap-rest ;

: hanging-indent	   \ left justify current line and indent rest of paragraph
	read-only? if nowrap-msg exit then
	0 !dotofs  ljust-line
	l-margin dup indent-size + !l-margin \ adjust left margin
	wrap-rest
	!l-margin ;

: indent							\ indent current line and rest of paragraph
	read-only? if nowrap-msg exit then
	l-margin dup indent-size + !l-margin \ adjust left margin
	0 !dotofs  ljust-line wrap-rest
	!l-margin ;

in-hidden

0 value holdln
0 value holdofs

: hold-location
	dotln to holdln  dotofs to holdofs
	dotln trimmed-len r-margin <= if  exit  then
	dotofs dup wrap-location dotofs < if
		drop exit
	then
	dotofs 0= if  drop exit  then
	dotofs - l-margin + to holdofs
	dotln 1+ to holdln ;

in-editor

: _auto-word-wrap
	word-wrap? 0= if exit then
	prev-char bl = if exit then
	hold-location
	holdofs r-margin >  				\ line too long?
	word-wrap
	holdln holdofs rot if   			\ handle it
		drop 1+ l-margin 1+
	then
	!dotofs !dotln ;

' _auto-word-wrap is auto-word-wrap

: set-r-margin
	dotofs !r-margin ;

: set-right-margin ( n -- )
	dup 1 l-limit 1+ within if
		1- !r-margin
	else drop
	then ;

: set-default-right-margin ( n -- )
	dup 1 l-limit 1+ within if
		to default-right-margin
	else drop
	then ;

: set-l-margin
	dotofs !l-margin ;

: set-left-margin ( n -- )
	dup 1 l-limit 1+ within if
		1- !l-margin
	else drop
	then ;

: set-default-left-margin ( n -- )
	dup 1 l-limit 1+ within if
		to default-left-margin
	else drop
	then ;
