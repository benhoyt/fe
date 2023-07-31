\ LINE  --  line routines   								11-01-99 21:01:36

in-hidden

\ all these routines act on dot line

: _overwrite-char ( char -- )
	dotptr c! ;

: _insert-as-dot-line ( addr cnt -- )   \ string inserted as new dot line
	_open-array
	!dotlen !dotlp
	#lines 1+ !#lines ; 				\ adjust #lines

: _insert-extra?					\ don't never put nuttin on dummy end line
	dotln #lines = if   				\ dot line is end line
		empty-line 0 _insert-as-dot-line \  so insert an extra
		0 !dotofs
	then ;

: line-fit? ( cnt -- flag ) 		\ will cnt more (- fewer) bytes fit line?
	dotlen + alloc-size  dotlen alloc-size = ;

: extend-dot-line ( cnt -- )			\ allocate new line cnt larger
	dotlen + lmalloc				( addr )
	dotlp over dotlen move  		( addr )
	dotlp lmfree
	!dotlp ;

: open-dot-line ( cnt -- )  			\ open line for cnt bytes
	dotptr + dotptr swap dot-#toeol move ;

: _ins-string ( addr cnt -- )   		\ insert string into dot line
	_insert-extra?
	dup line-fit? 0= if   				\ if not fit, extend
		dup extend-dot-line
	then
	dup open-dot-line   	( addr cnt )
	tuck dotptr swap move   ( cnt )
	dup dotlen + !dotlen
	dotofs + !dotofs ;

: _ins-nchars ( char cnt -- )   		\ insert cnt chars into dot line
	_insert-extra?
	dup >r line-fit? 0= if	( char R: cnt )
		r@ extend-dot-line
	then
	r@ open-dot-line
	dotptr r@ rot fill  	( R: cnt )
	r@ dotlen + !dotlen
	r> dotofs + !dotofs ;

: _delete-nchars ( cnt -- ) 			\ delete cnt chars from dot line
	dup dotlen = if 			( cnt ) \ delete all chars?
		dotlp lmfree
		empty-line !dotlp 0 !dotlen
		drop exit
	then
	>r  			( R: cnt )  		\ delete some chars
	dotptr r@ + dotptr dot-#toeol r@ - move \ close up line
	r@ negate line-fit? 0= if 		( R: cnt ) \ shrink line if needed
		dotlen r@ - lmalloc 		( addr R: cnt )
		dotlp over dotlen r@ - move ( addr R: cnt )
		dotlp lmfree
		!dotlp
	then
	dotlen r> - !dotlen ;

: _split-ln 							\ split line at dot
	dotofs lmalloc >r   		( R: ptr )
	dotpos r@ swap move 				\ move first part of line
	dotofs dup 0 !dotofs _delete-nchars   ( cnt R: ptr )
	r> over _insert-as-dot-line !dotofs ;

: _join-line							\ join next line to this
	dotlen 0<>  						\ if dot line is not empty
	dotln 1+ #lines = and if			\  and next line is dummy end line
		exit							\  don't join
	then
	dotln 1+ nth-str			( adr cnt )
	dotofs >r dotlen !dotofs	( adr cnt R: dotofs )
	_ins-string r> !dotofs
	_close-array
	#lines 1- !#lines ;

in-editor

: c-char ( -- char )					\ char at dot
	dotlen dotofs = if
		end-line-char
	else
		dotptr c@
	then ;


