\ VARS  --  Editor variables								06-01-99 20:58:42

in-editor

\ Screen size
: screen-cols   						\ # cols on screen
	screen-size drop ;
: screen-rows   						\ # rows on screen
	screen-size nip ;

variable tab-ch  						\ tab char
 	9 tab-ch !

10 value lf-ch							\ New line char
10 value end-line-char					\ end of line char returned by c-char

41 value cmnt-col   					\ col on which to start comments

20 constant tabmax  					\ maximum size of tab

\ Line length can be arbitrarily large, but note required buffers in file.f
255 constant l-limit					\ maximum read line length

\ Current status variables
false value editing?
false value draw-style					\ which line draw mode?
true value trim-line?   				\ lines to be trimmed during file save?
false value defining?   				\ are we defining a macro
true value auto-indent  				\ default is auto-indent
4 value read-tabsize					\ 4 = initial read tabsize
true value save-with-tabs   			\ tab replaces tabsize spaces when saving
false value detab-on-read				\ convert tabs to spaces when reading
true value use-hard-tabs				\ tab key inserts hard tabs
0 value #rows-to-keep   				\ number of rows to keep when paging
76 value default-right-margin   		\ right margin for new buffer
1 value default-left-margin 			\ left margin for new buffer
4 value indent-size 					\ size of paragraph & hanging indents

\ File extensions wordlist
wordlist value file-extensions


\ utility words

: $move ( src dest -- ) 				\ move counted string src to dest
	over c@ 1+ move ;

: $icmp ( src dest - l/e/g )			\ compare two counted strings
	>r count r> count icompare ;

: $c+ ( char dest -- )  				\ add char to end of dest string
	1 over c+!  						\ increment count of dest
	count + 1- c! ;

: mallocate ( u -- a-addr )
	allocate throw ;

: mfree ( a-addr -- )
	free throw ;
