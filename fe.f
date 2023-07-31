\ FE  --  Makefile for a Forth Editor by Bruce Hoyt  		20-01-02 21:33:06

\   With apologies to micro-emacs from which some ideas were stolen
\   then modified almost beyond recognition. A few names still remain,
\   like dot and mark. The remnants of C code may still show in a few
\   places :-(

0 [if] \ Comment ───────────────────────────────────────────────────────┐
																		│
A file is read, stored internaly, and written by lines. 				│
Internally lines are stored in allocated memory.						│
An array of pointers & lengths is used to access them.  				│
This array is re-sized as necessary.									│
																		│
A doubly linked list (ring) of buffers holds information about each 	│
file being edited. There are separate buffer rings for deleted stuff	│
and marked block deletions (cut) which enable undelete and paste.  		│
																		│
Key sequences may be bound to functions as in bios.key					│
																		│
Error handling is minimal.  											│
																		│
[then] \ End comment ───────────────────────────────────────────────────┘

hex
0030 value FE-version
decimal

vocabulary editor
also editor definitions

vocabulary ed-hidden

: in-editor  only forth also editor definitions also ed-hidden ;
: in-hidden  only forth also editor also ed-hidden definitions ;
: in-forth   only forth definitions also editor also ed-hidden ;

cr .(   vars.f ..... some global variables)   	include .\vars.f
cr .(   keybind.f .. key binding routines) 		include .\keybind.f
cr .(   line-ed.f .. line editing routines)    	include .\line-ed.f

cr .(   dlist.f .... doubly linked lists)  		include .\dlist.f
cr .(   buf.f ...... buffer handling)  			include .\buf.f
cr .(   line.f ..... line handling)    			include .\line.f

	\ windows are not yet implemented
cr .(   wind.f ..... window handling)  			include .\wind.f
cr .(   disp.f ..... screen display routines)  	include .\disp.f
cr .(   linein.f ... line input)   				include .\linein.f
cr .(   file.f ..... file handling)    			include .\file.f
cr .(   cursor.f ... cursor motion routines)   	include .\cursor.f
cr .(   basic.f .... basic edit routines)  		include .\basic.f
cr .(   block.f .... block routines)   			include .\block.f
cr .(   edit.f ..... editing functions)    		include .\edit.f
cr .(   search.f ... search and replace routines) include .\search.f
cr .(   misc.f ..... miscellaneous routines)   	include .\misc.f
cr .(   draw.f ..... line drawing routines)    	include .\draw.f
cr .(   main.f ..... the main edit loop)   		include .\main.f
cr .(   cmnt.f ..... comment routines) 			include .\cmnt.f
cr .(   macro.f .... key stroke macros)    		include .\macro.f
cr .(   wrap.f ..... word wrapping)    			include .\wrap.f

allow-source-locating [if]
cr .(   locate.f ... locate source files)  		include .\locate.f
[then]

cr .(   fe.key ..... FE key bindings)   		include .\fe.key

OS-type 2 = [if]	\ WIN
cr .(   clip.f ....... Clipboard)				include win\clip.f
[then]

