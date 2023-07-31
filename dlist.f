\ DLIST  --  doubly linked list routines					06-01-99 21:13:39

in-hidden

0
cell field dl>flink 					\ forward link
cell field dl>blink 					\ backward link
constant dl-links-size

: dl-forward ( dl1 -- dl2 ) dl>flink @ ;
: dl-backward ( dl1 -- dl2 ) dl>blink @ ;
: dl-!flink ( addr dl -- ) dl>flink ! ;
: dl-!blink ( addr dl -- ) dl>blink ! ;

: dl-self ( item -- )   				\ link an item to itself
	dup dup dl-!flink
	dup dl-!blink ;

: dl-link ( item dest -- )  			\ link item before dest
	dup dl-backward >r  ( item dest  R: prev )
	2dup dl-!blink  					\ dest blinks to item
	over r@ dl-!flink   				\ prev flinks to item
	over dl-!flink  	( item  R: prev ) \ item flinks to dest
	r> swap dl-!blink ;   				\ item blinks to prev

: dl-unlink ( item -- nextitem )		\ unlink item from the list
	dup dl-forward swap dl-backward over	( next prev next - )
	2dup dl-!blink  					\ set the blink in next item
	swap dl-!flink ;  					\ set the flink in prev item
