\ CURSOR  --  Cursor motion routines                        11-01-99 20:52:03

in-editor

: c-bol                                 \ goto beginning of line
    0 !dotofs ;

: c-eol                                 \ goto end of line
    dotlen !dotofs ;

: c-bof                                 \ goto beginning of buffer
    dotln 0> if
        0 !dotln 0 !topln
        flagwindow
    then
    c-bol ;

: c-eof                                 \ goto end of buffer
    dotln #lines < if
        #lines !dotln
        windrows 1- adjust-top-line
        flagwindow
    then
    c-bol ;

: goto-line# ( n -- )
    1- dup 0 #lines 1+ within 0= if     \ check for valid line#
        drop dotln
    then
    !dotln c-bol
    ?middle                             \ middle of screen
    flagwindow ;

: str>n ( addr cnt -- n )               \ convert str to binary
    0 0 2swap >number
    2drop drop ;

: goto-line
    msg" Jump to which line? " linein
    line-esc if exit then
    ed-tib ed-#tib @ source!
    parse-word str>n
    goto-line# ;

in-hidden

: get-dotofs ( dispofs -- dotofs )      \ compute the equivalent dotofs
    >r dotlp 0
    begin     ( dotptr disp R: dispofs )
        dup r@ <
    while
        over c@ tab-ch c@ = if
            tabsize + dup tabsize mod -
        else
            1+
        then
        1 under+
    repeat
    dup r> <> if  1- then               \ middle of tab, so force back
    drop dotlp - ;

0 value up/down                         \ signal up or down cursor motion

: adjust-dotofs
        prevcol get-dotofs dotlen min !dotofs ;

: set-prevcol
    prevcol -1 = if                     \ not set
        dispofs to prevcol              \  so set it now
    then ;

: set-up/down
    true to up/down  adjust-dotofs ;

in-editor

: c-down
    dotln #lines < if
        flagdot set-prevcol
        windrow 1+ windrows = if
            topln 1+ !topln
[ vt100-scroll ] [if]
            windrows 2- th-row-flag-on flagscrollup
[else]
            flagwindow
[then]
        then
        dotln 1+ !dotln
    then
    flagdot set-up/down ;

: c-up
    dotln 0> if
        windrow 0= if
            topln 1- !topln
[ vt100-scroll ] [if]
            flagscrolldn
[else]
            flagwindow
[then]
        then
        flagdot set-prevcol
        dotln 1- !dotln
    then
    flagdot set-up/down ;

: c-tos                                 \ goto top of screen
    set-prevcol  topln !dotln
    flagwindow set-up/down ;

: c-bos                                 \ goto bottom of screen
    set-prevcol topln windrows + 1- #lines min !dotln
    flagwindow set-up/down ;

: c-lock-scroll-down                    \ scrl text down, cursor on fixed row
    topln if
        windrow c-up if                 \ cursor on top row of window?
            topln 1- !topln
[ vt100-scroll ] [if]
            flagscrolldn
[else]
            flagwindow
[then]
        then
    then
;

: c-lock-scroll-up                      \ scrl text up, fixed cursor line
    topln #lines < if
        windrow windrows 1- = c-down 0= if \ dot on bottom row of window?
            topln 1+ !topln
[ vt100-scroll ] [if]
            flagscrollup windrows 1- th-row-flag-on
[else]
            flagwindow
[then]
        then
    then
;

: c-scroll-down                         \ scrl text down, dot unchanged
    topln if
        set-prevcol
        windrow windrows 1- = if
            c-up
        then
        topln 1- !topln
[ vt100-scroll ] [if]
        flagscrolldn set-up/down
        0 th-row-flag-on
[else]
        flagwindow set-up/down
[then]
    then
;

: c-scroll-up                           \ scrl text up, cursor on same line
    topln #lines <> if
        set-prevcol
        windrow 0= if
            c-down
        then
        topln 1+ !topln
[ vt100-scroll ] [if]
        flagscrollup set-up/down
        windrows 1- th-row-flag-on
[else]
        flagwindow set-up/down
[then]
    then
;

in-hidden

: page-amt
    windrows #rows-to-keep - 0 max ;

in-editor

: c-page-down                           \ go down full screen
    set-prevcol
    page-amt topln + #lines > if
        flagdot  #lines !dotln  flagdot
    else
        topln page-amt + !topln
        dotln page-amt + #lines min !dotln
        flagwindow
    then
    set-up/down ;

: c-page-up                             \ go up full screen
    set-prevcol
    topln 0= if
        flagdot  0 !dotln  flagdot
    else topln page-amt < if
        dotln topln - !dotln
        0 !topln
        flagwindow
    else
        topln page-amt - !topln
        dotln page-amt - !dotln
        flagwindow
    then then
    set-up/down ;

: c-right                               \ go right
    dot-#toeol if
        dotofs 1+ !dotofs
    else
        dotln #lines < if
            c-down c-bol
            false to up/down
        then
    then ;

: c-left                                \ go left
    dotofs if
        dotofs 1- !dotofs
    else
        dotln 0> if
            c-up c-eol
            false to up/down
        then
    then
;

in-hidden

: skip_white
    begin
        c-char end-line-char <>
        c-char iswhite? and
    while
        c-right
    repeat ;

: skip_nwhite
    begin
        c-char iswhite? 0=
    while
        c-right
    repeat ;

in-editor

: c-word-right                          \ move one word right
    dot-#toeol 0= if
        c-right
    else c-char iswhite? if
        skip_white
    else
        skip_nwhite skip_white
    then then
;

in-hidden

: back_n/white ( flag -- )              \ skip back over white or non-white
    begin
        dotofs
    while
        dotofs 1- !dotofs
        c-char iswhite? over xor 0= if
            drop  dotofs 1+ !dotofs  exit
        then
    repeat drop ;

: back_white false back_n/white ;       \ skip back over white space
: back_nwhite true back_n/white ;       \ skip back over non-white space

in-editor

: c-word-left                           \ move one word left
    dotofs 0= if
        c-left
    else
        dotofs dup 1- !dotofs c-char swap !dotofs iswhite? if
            back_white
            back_nwhite
        else
            back_nwhite
        then
    then
;

: c-col ( n -- )                        \ goto given column
    1- to prevcol
    adjust-dotofs ;

in-hidden

10 value #marks
create marker_line#s #marks cells allot
create marker_row#s #marks allot
create marker_col#s #marks allot
create marker_fnameptr here #marks cells erase #marks cells allot

: goto-marker ( n - )
    dup cells marker_fnameptr + @       \ point to file name
    ?dup 0= if drop exit then           \ no mark set
    find-buffer ?dup if                 \ find the buffer, if it's in memory
        switch-buffer                   \ and switch to it
        dup cells marker_line#s + @ goto-line# \ line#
        dup marker_col#s + c@ c-col \ prev col#
        dup marker_row#s + c@ adjust-top-line \ prev row#
    then
    drop ;

: set-marker ( n - )
    dotline# over cells marker_line#s + !
    windrow over marker_row#s + c!
    col# over marker_col#s + c!
    dup cells marker_fnameptr + @ if    \ free name memory
        dup cells marker_fnameptr + @ mfree
    then
    bname c@ 1+ mallocate ( n nptr )
    tuck swap cells marker_fnameptr + ! \ point to file name
    bname swap $move ;                  \ save file name

in-editor

: goto-marker0
    0 goto-marker ;
: goto-marker1
    1 goto-marker ;
: goto-marker2
    2 goto-marker ;
: goto-marker3
    3 goto-marker ;
: goto-marker4
    4 goto-marker ;
: goto-marker5
    5 goto-marker ;
: goto-marker6
    6 goto-marker ;
: goto-marker7
    7 goto-marker ;
: goto-marker8
    8 goto-marker ;
: goto-marker9
    9 goto-marker ;

: set-marker0
    0 set-marker ;
: set-marker1
    1 set-marker ;
: set-marker2
    2 set-marker ;
: set-marker3
    3 set-marker ;
: set-marker4
    4 set-marker ;
: set-marker5
    5 set-marker ;
: set-marker6
    6 set-marker ;
: set-marker7
    7 set-marker ;
: set-marker8
    8 set-marker ;
: set-marker9
    9 set-marker ;
