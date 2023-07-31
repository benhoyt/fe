\ BASIC  --  Basic editing functions						11-01-99 20:52:23

in-hidden

: _split-line   						\ split current line at cursor
	_split-ln set-modified
	markln dotln = if   				\ split marked line?
		dotofs markofs <= if			\  and before the mark?
			markofs dotofs - !markofs   \ new mark offset
			dotln 1+ !markln			\ new mark line
		then
	then ;

: no-insert msg" Can't insert in read-only mode" ;

: split-line							\ split a line at cursor, if allowed
	read-only? if  no-insert exit  then
	_split-line ;

: adjust-mark ( cnt -- cnt )			\ adjust markofs if needed
	markln dotln = if
		dotofs markofs < if				\ dotofs on marklp before mark?
			dup markofs + !markofs  	\ adjust markofs
		then
	then
	set-modified ;

: ins-string ( addr cnt -- )			\ insert string
	adjust-mark _ins-string ;

: ins-chars ( chr cnt -- )  			\ insert any char except LF
	adjust-mark _ins-nchars ;

: _insert-chars ( char n -- )   		\ insert n chars in dotln at dotofs
	read-only? if  2drop no-insert exit  then
	dup 0<= if  						\ anything to do?
		2drop exit  					\ no
	then
	ins-chars ;

: _insert-string ( addr cnt -- )		\ insert string
	read-only? if  2drop no-insert exit  then
	dup 0<= if  						\ anything to do?
		2drop exit  					\ no
	then
	ins-string ;

\ ─────────────────────────────────────────────────────────────────────────────
\ Delete & undelete routines
\ ─────────────────────────────────────────────────────────────────────────────

\ Global variables for delete & undelete
3 constant max-#udbs   					\ maximum # of undelete buffers
0 value #udbs   						\ current # in undelete buffers
0 value last-udb						\ last udb deleted from
0 value ud-operation?   				\ was previous operation an undelete?
0 value del-operation?  				\ was previous operation a delete?
0 value paste-operation?				\ last ud-operation a paste operation?
0 value save-curbuf 					\ save current buffer here
true value udb-closed?  				\ extend udb until non-del operation
true value save-deleted?				\ does delete store deleted chars?
true value del-right?   				\ did we delete right?
false value doing-paste?				\ are we doing a block operation?

: init-udbs								\ initialise undelete buffer values
	0 to #udbs ;

: create-udb							\ create undelete buffer, make it curbuf
	doing-paste? if  c" PasteBuf"  else  c" DelBuf"  then
	create-buffer dup to curbuf  ( bp ) \ also use it
	udb-head dl-forward dl-link 		\ make this buffer first in list
	_split-line 						\ extra line to b/e-udb work
	0 to udb-closed? ;

: select-udb
	udb-closed? if  					\ add to first udb, or use a new one?
		#udbs max-#udbs >= if   		\ delete oldest buffer?
			udb-head dl-backward to curbuf
			curbuf dl-unlink drop
			b-destroy
		else
			#udbs 1+ to #udbs
		then
		create-udb
	else								\ not closed
		udb-head dl-forward to curbuf   \ add to first udb
	then
;

10 value min-delete-lines   			\ min # of free lines in delete buffer

: >udb  								\  changes to current udb, saves curbuf
	curbuf to save-curbuf
	min-delete-lines to min-free
	select-udb ;

: udb>  								\  restores old buffer, change from udb
	min-text-lines to min-free
	save-curbuf to curbuf ;

: b/e-udb   							\ move to beginning/end of udb
	del-right? if
		#lines 1- dup nth-len  \ need extra line in create-udb for this to work
	else
		0 0
	then
	!dotofs !dotln ;

: lf>udb								\ add an LF to the udb
	save-deleted? if					\ if we are saving to udb
		>udb
		b/e-udb
		_split-line
		udb>
	then
;

: join-line 							\ join dotln and the next line together
	dotln #lines = if  exit  then  		\ do nothing at last line?
	dotln markln < if
		markln 1- !markln   			\ fix mark if necessary
		dotln markln = if
			dotlen markofs + !markofs
		then
	then
	_join-line lf>udb ;					\ add a LF to the undelete buffer

: chars>udb ( addr n -- )   			\ copy n chars from addr insert into udb
	save-deleted? if
		>udb							\  change to next delete buf
		b/e-udb
		_ins-string
		udb>
	else
		2drop
	then
;

: delete-nchars ( n1 -- n2 )	\ delete n1 chars, or # remaining on this line
	negate adjust-mark negate
	dot-#toeol 	( n1 #toeol )		\ n2 is n1 - number deleted
	2dup >= if 	( n1 #toeol )		\ delete rest of line?
		dotptr over chars>udb
		dup _delete-nchars
		-   							\ adjust n1
	else								\ delete chars within line
		drop dotptr 				( n1 addr )
		over chars>udb  			( n1 )
		_delete-nchars
		0
	then
;

: _delchars ( cnt -- )  				\ delete cnt chars
	begin
		?dup
	while
		dotlen dotofs = if  			\ at end of line?
			1- join-line
		else
			delete-nchars
		then
	repeat
	set-modified ;

: delchars ( cnt -- )   				\ delete cnt chars
	read-only? if  drop msg" Can't delete in read-only mode" exit  then
	_delchars ;

: undel ( udb -- )  					\ undelete from udb
	dotln !markln dotofs !markofs   	\ mark where we are
	curbuf over to curbuf   ( udb textbuf )
	#lines 0 ?do
		i nth-str   		( udb textbuf dotptr dotlen )
		2 pick to curbuf				\ to textbuf
		_ins-string _split-ln c-right
		over to curbuf  				\ back to udb
	loop					( udb textbuf )
	to curbuf drop
	false to save-deleted?
	c-left 1 delchars   				\ remove extra LF from textbuf
	true to save-deleted?
	swap-dot/mark   					\ to start of undeleted stuff
	-1 to prevcol ;

: #chars ( -- n )   					\ count # chars in buffer
	0 #lines 0 ?do  		( n )
		i nth-len 1+ +
	loop ;

: redelete ( udb -- )   				\ delete stuff already undeleted
	curbuf swap to curbuf   	( textbuf )
	#chars
	swap to curbuf
	false to save-deleted?  		   \ do not want to store chars
	1- delchars
	true to save-deleted? ;

: undelete-last 						\ undelete from last udb
	udb-head dup dl-forward = if		\ any buffers present?
		msg" Nothing deleted"
	else
		udb-head dl-forward dup undel
		to last-udb
	then
;

: undel-prev							\ undelete from previous udb
	last-udb 0= if
		undelete-last
	else
		last-udb dl-forward 	( next-udb )
		dup udb-head = if
			last-udb redelete   		\ take out stuff already undeleted
			to last-udb
		else
			last-udb udb-head <> if
				last-udb redelete   	\ take out stuff already undeleted
			then
			dup to last-udb
			undel
		then
	then
;
