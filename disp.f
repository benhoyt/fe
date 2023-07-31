\ disp.f  --  Editor screen display routines                  11-01-99 20:59:31

in-hidden

\ Default colours for editor
hex
17 value normal-colour                  \ normal text
1F value dot-colour                     \ text on dot line
71 value marked-colour                  \ selected text, between dot and mark
71 value dot+marked-colour              \ selected text on dot line
71 value status-colour                  \ status line colour
decimal

in-editor

\ Used to set display colours in FE.CFG
: set-colours ( status mrkdot mrk dot nrm -- )
    to normal-colour                    \ normal text
    to dot-colour                       \ text on cursor line
    to marked-colour                    \ highlighted text in marked block
    to dot+marked-colour                \ highlighted text also on cursor line
    to status-colour ;                  \ status line

\ Default char to use for hard tab display
variable tab-disp                       \ display this char for tab
    bl tab-disp !

in-hidden

0 value many-spaces                     \ line of spaces for fast erase to eol
0 value row-buf                         \ build one display row here
variable row-buf-ofs                    \ offset into row-buf

\ Allocate buffers for screen size
: allocate-vid-bufs ( -- )
    screen-cols tabmax max mallocate    \ enough for # cols on screen
    to many-spaces
    screen-cols mallocate to row-buf
    many-spaces screen-cols tabmax max blank ;

\ Re-allocate buffes when screen size changes
\ : re-allocate-vid-bufs ( -- )
\    many-spaces mfree  row-buf mfree  allocate-vid-bufs ;

\ current display position and current colour
variable video-col
variable video-row
variable video-colour

\ Display string at current display position
: video-type ( addr cnt -- )
    tuck
    video-col @ windstcol + video-row @ windstrow +
    video-colour @
    type-chars  video-col +! ;

\ Display spaces from current display position to col n
: blank>coln ( n -- )
    video-col @ - dup 0> if
        many-spaces swap video-type
    else drop then ;

: erase-eol
    windcols blank>coln ;

0 value msg-active                      \ signal there is an active message

\ Compiled by msg"
: (msg") ( c-addr -- )
    curbuf 0= if  abort"msg !  -2 throw  then   \ in case editor not initialized
    true to msg-active
    status-colour video-colour !        \ status line colour
    status-line# video-row !  video-col off
    count tuck video-type   ( cnt )     \ message to cell buffer, remember cnt
    erase-eol
    windstcol + status-line# windstrow + at-xy ; \ position cursor for any input

\ Parse a message and compile for display
: msg" ( "message" -- )
    postpone c" postpone (msg") ; immediate

\ Erase a whole row in window
: erase-row ( row -- )
    video-row ! video-col off
    normal-colour video-colour !
    erase-eol ;

\ Show part of a row; source string in row-buf array
: show-part-row ( -- )
    row-buf row-buf-ofs @ video-type
    row-buf-ofs off ;                   \ empty row-buf array

\ Global variables for display routines
variable dspofs                         \ display offset of char
0 value ledge                           \ left edge of window
0 value redge                           \ right edge of window

\ Initialise the row-buf array and global vbls; ready to display a row
: init-row ( row -- )
    windofs dup to ledge windcols + to redge
    video-row !  video-col off
    dspofs off  row-buf-ofs off ;

\ Display the extra spaces needed for 1 tab
: disp-1tab ( -- n )
    tabsize dspofs @ over mod - ( n )   \ n=chars to next tab stop
    row-buf row-buf-ofs @ +     ( n a )
    over 1 ?do                  ( n a ) \ 1 since tab already placed
        dspofs @ i + ledge redge within if
            bl over c! 1+
            1 row-buf-ofs +!
        then
    loop drop ;     ( n )

\ Display 1 ch if it is in window, handle tabs
: disp-1ch ( ch -- )
    ledge dspofs @ <= if        ( ch )
        dup dup tab-ch c@ = if  ( ch ch )
            drop tab-disp c@    ( ch ch' ) \ use instead of tab
        then
        row-buf row-buf-ofs @ + c!
        1 row-buf-ofs +!
    then                        ( ch )
    tab-ch c@ = if                      \ if tab
        disp-1tab                       \   display extra spaces needed
    else 1
    then dspofs +! ;

\ Display part of line, handle window edges
\ For speed, write this and disp-1ch in assembler
: _disp-part ( ptr len -- )
    bounds ?do                        \ build in row-buf
        redge dspofs @ <= if          \ don't display past right side of window
            unloop exit
        then
        i c@ disp-1ch
    loop ;

\ Display part of line, handle window edges
: disp-part ( ptr len -- )
    _disp-part show-part-row ;

\ Display a 1 colour row
: disp1clr ( row clr -- )
    video-colour !      ( row )
    dup init-row
    topln + nth-str
    disp-part erase-eol ;               \ erase the rest of the line

\ Display a 2 colour row; colour changes from clr1 to clr2 at ofs
: disp2clr ( row ofs clr1 clr2 -- )
    >r video-colour ! >r    ( row R: clr2 ofs )
    dup init-row
    topln +                 ( ln R: clr2 ofs )
    dup nth-lp r@ disp-part
    nth-str r> /string      ( lp+ofs len R: clr2 )
    r> video-colour !               ( lp+ofs len )
    disp-part erase-eol ;               \ erase the rest of the line

\ Display a 3 colour row; colour changes from clr1 to clr2 and back
\ at dotofs and markofs, which ever is first
: disp3clr ( row clr1 clr2 -- )
    >r video-colour !   ( row R: clr2 )
    dup init-row
    topln +             ( ln R: clr2 )
    dup nth-lp dotofs markofs min disp-part
    video-colour @ r> video-colour ! >r     ( ln R: clr1 )
    dup nth-lp dotofs markofs 2dup > if
        swap
    then
    over - >r + r>          ( ln lp+ofs len R: clr1 )
    disp-part
    r> video-colour !       ( ln )
    nth-str dotofs markofs max /string ( lp+ofs len )
    disp-part erase-eol ;               \ erase the rest of the line

\ Select colours and ofs as required
: dispN ( row -- )
    normal-colour disp1clr ;
: dispD ( row -- )
    dot-colour disp1clr ;
: dispM ( row -- )
    marked-colour disp1clr ;
: disp2N ( row -- )
    markofs normal-colour marked-colour disp2clr ;
: disp2M ( row -- )
    markofs marked-colour normal-colour disp2clr ;
: disp2D ( row -- )
    dotofs dot-colour dot+marked-colour disp2clr ;
: disp2DM ( row -- )
    dotofs dot+marked-colour dot-colour disp2clr ;
: disp3D ( row -- )
    dot-colour dot+marked-colour disp3clr ;
: disp3N ( row -- )
    normal-colour marked-colour disp3clr ;

\ Jump table used when highlighting is on
create marked-table
\   before      equal       after mark
  ' dispN ,   ' disp2N ,  ' dispM ,      \ before dot
  ' disp2D ,  ' disp3D ,  ' disp2DM ,    \ equal dot
  ' dispM ,   ' disp2M ,  ' dispN ,      \ after dot

\ Is row before, same or after dot row? 0=before, 1=same, 2=after
: cmp-dot ( row -- 0|1|2 )
    topln + dup dotln < if
        drop 0
    else dotln = if
        1
    else
        2
    then then ;

\ Is row before, same or after mark row? 0=before, 1=same, 2=after
: cmp-mark ( row -- 0|1|2 )
    topln + dup markln < if
        drop 0
    else markln = if
        1
    else
        2
    then then ;

\ Display a row when highlighting is on
: disp-hilite ( row -- )
    dup cmp-dot 3 *         ( row n )
    over cmp-mark +         ( row n )
    cells marked-table + @ execute ;

\ Display a row
: display-row ( row -- )
    show-marked? if                     \ is highlighting on?
        disp-hilite
    else
        dup topln + dotln = if          \ No, so it's either
            dispD                       \ a dot line
        else
            dispN                       \ or a normal line
        then
    then ;

\ Display all flagged rows
: display-loop ( -- )
    windrows 0 ?do
        i th-row-flag? if               \ display this line?
            i topln + #lines < if       \ only if not past last line in buffer
                i display-row
            else
                i erase-row             \ otherwise erase the row
            then
            i th-row-flag-off
        then
    loop ;

\ Compute display offset of dot char in text, handles tabs
: dispofs ( -- n )
    tabsize 0               ( nexttab dispofs )
    dotlp dotofs bounds ?do
        i c@ tab-ch c@ = if             \ is this char a tab?
            drop dup tabsize under+     \ yes, display offset to next tab stop s
        else
            1+                          \ incr display offset
            2dup = if                   \ at a tab stop?
                tabsize under+          \ yes, find next tab stop
            then
        then
    loop  nip ;

in-editor

: col# ( -- pos ) dispofs 1+ ;          \ col # ( 1 based)
: dotline# ( -- n ) dotln 1+ ;          \ line # ( 1 based)

in-hidden

create npad 10 allot                    \ buffer for number conversion

\ Use npad in case at-xy uses numeric conversion area
\ Gforth was guilty
: _num-type ( addr cnt -- )
    npad swap dup >r move npad r> video-type ;

\ Display a positive integer
: num-type ( u -- )
    0 <# #s #> _num-type ;

\ Display the editor status line
: display-status ( -- )
    status-colour video-colour !        \ status line colour
    status-line# video-row !  video-col off
    s" L:" video-type  dotline# num-type
    s" /" video-type  #lines 1+ num-type
    14 blank>coln
    s" C:" video-type  col# num-type
    22 blank>coln
    auto-indent? if s" I" else s" i" then video-type
    overwrite? if s" O" else s" o" then video-type
    read-only? if s" R" else s" r" then video-type
    word-wrap? if s" W" else s" w" then video-type
    draw-style ?dup if 1 = if s" S" else s" D" then else s" d" then video-type
    tabsize num-type
    30 blank>coln
    c-char hex 0 <# # # #> decimal _num-type
    33 blank>coln
    bf-changed b.flags test-bits if s" *" else s"  " then video-type
    curwind w>buf @ b>name @ count
    windcols 1- video-col @ - min video-type
    windcols 1- blank>coln ;            \ so screen doesn't scroll

\ Set topln so dotln is cnt from top
: adjust-top-line ( cnt -- )
    dotln swap - 0 max !topln ;

\ Is the dot line on screen?
: dot-on-screen? ( -- flag )
    dotln topln dup windrows + within ;

\ Set topln so dotln is cnt from top if dot line is not on screen
: ?adjust-top-line ( cnt -- )
    dot-on-screen? 0= if  adjust-top-line  else  drop  then ;

\ Set topln to middle of screen if dot line is not on screen
: ?middle ( cnt -- )
    windrows 2/ ?adjust-top-line ;

\ Set the col offset of the window so that cursor is in window
: adjust-windofs ( -- )
    dispofs dup windofs dup windcols + within if
        drop exit
    then
    dup windofs >= if
        windcols - 1+
    then
    !windofs flagwindow ;

-1 value prevcol            \ cursor col on prev row after vertical motion

vt100-scroll [if]

0 value screen-move-type                \ 0=none; 1=scroll up; 2=scroll down
create del-line-code 27 c, '[ c, 'M c,  \ = VT100 delete line
create ins-line-code 27 c, '[ c, 'L c,  \ = VT100 insert blank line

: flagscrollup
    1 to screen-move-type ;

: flagscrolldn
    2 to screen-move-type ;

: scrollup
    0 0 at-xy  del-line-code 3 type ;   \ delete top line

: scrolldn
    0 0 at-xy  ins-line-code 3 type ;   \ insert blank top line

: screen-moves
    screen-move-type ?dup if
        1 = if
            scrollup
        else
            scrolldn
        then
        0 to screen-move-type
    then ;

[then]

\ Display the cursor
: display-cursor ( -- )
    dispofs windofs - windstcol +
    windrow windstrow + at-xy ;

\ Display the text in window
: display-text ( -- )
    show-marked? if                     \ moving cursor in marked mode
        flagdot                         \  must redisplay dot line
    then
    adjust-windofs                      \ need any window shifting?
[ vt100-scroll ] [if]
    screen-moves
[then]
    display-loop ;

in-editor

Windows [if]
    kernel32 import: SetConsoleTitle ( zstr -- 0=err )

    : display-title ( -- )
        curwind w>buf @ b>name @ count
        dup 6 + s-buf-mem >r
        s" Edit " r@ zplace
        r@ zappend
        r@ >win-sep
        r> SetConsoleTitle drop ;
[then]

\ Display text, status line, and cursor
: display ( -- )
    display-text
    msg-active 0= if                    \ only display status if no message
        display-status
        [ Windows ] [if]  display-title  [then]
    then
    display-cursor ;

Windows [if]    \ WIN32

\ Used when entering the editor
: init-editor-screen ( -- )
    normal-colour set-colour
    screen-size set-console-buffer-size
    80 set-cursor-size ;

\ Used when exiting the editor
: init-forth-screen ( -- )
    7 set-colour
    save-console-buffer-size 2@ set-console-buffer-size
    80 set-cursor-size
    0 screen-rows 1- at-xy eeol ;

\ Used when exiting from editor to forth command line or to shell
: restore-screen ( -- )
    7 set-colour
    save-console-buffer-size 2@ set-console-buffer-size
    3 _stdout SetConsoleMode drop
    0 screen-rows 1- at-xy eeol ;

[then]

Linux [if]    \ Linux

\ Used when entering the editor
: init-editor-screen ( -- )
    normal-colour set-colour
    80 set-cursor-size ;

\ Used when exiting the editor or entering forth
: init-forth-screen ( -- )
    normal-colour set-colour
    80 set-cursor-size
    0 screen-rows 1- at-xy eeol ;

\ Used when exiting from editor or forth command line to command shell
: restore-screen ( -- )
    7 set-colour
    0 screen-rows 1- at-xy eeol ;

[then]
