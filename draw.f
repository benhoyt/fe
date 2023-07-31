\ draw.f  2002-07-09  --  Line drawing routines

in-hidden

\ clockwise from top
    \ bit   direction
    \ 1     up
    \ 2     right
    \ 4     down
    \ 8     left

: leg-up? ( ch -- flag )
    1 and 0<> ;
: leg-rt? ( ch -- flag )
    2 and 0<> ;
: leg-dn? ( ch -- flag )
    4 and 0<> ;
: leg-lf? ( ch -- flag )
    8 and 0<> ;

hex

Linux [if]    \ Linux

\ These line drawing chars are in the trivial map
\ consolechars -m /usr/lib/kbd/consoletrans/trivial.trans

create draw-chars
\    0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
\   zz     u     r    ur     d    ud    rd    urd    l    ul    rl    url   dl    udl   rdl   urdl
\          ┴     ┬     ├     ─     ┼     ╞     ╟     ╚     ╔     ╩     ╦     ╠     ═     ╬     ╧
    00 c, C1 c, C2 c, C3 c, C4 c, C5 c, C6 c, C7 c, C8 c, C9 c, CA c, CB c, CC c, CD c, CE c, CF c,
\    0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
\   zz     u     r    ur     d    ud    rd    urd    l    ul    rl    url   dl    udl   rdl   urdl
\          ╤     ╥     ╙     ╘     ╒     ╓     ╫     ╪     ┘     ┌     █     ▄     ▌     ▐     ▀
    00 c, D1 c, D2 c, D3 c, D4 c, D5 c, D6 c, D7 c, D8 c, D9 c, DA c, DB c, DC c, DD c, DE c, DF c,
[then]


Windows [if]    \ Windows

create draw-chars
\    0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
\   zz     u     r    ur     d    ud    rd    urd    l    ul    rl    url   dl    udl   rdl   urdl
\                      └           │     ┌     ├           ┘     ─     ┴     ┐     ┤     ┬     ┼
    00 c,  1 c,  2 c, C0 c,  1 c, B3 c, DA c, C3 c,  2 c, D9 c, C4 c, C1 c, BF c, B4 c, C2 c, C5 c,

\    0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
\   zz     u     r    ur     d    ud    rd    urd    l    ul    rl    url   dl    udl   rdl   urdl
\                      ╚           ║     ╔     ╠           ╝     ═     ╩     ╗     ╣     ╦     ╬
    00 c,  3 c,  4 c, C8 c,  3 c, BA c, C9 c, CC c,  4 c, BC c, CD c, CA c, BB c, B9 c, CB c, CE c,

create half-chars  00 c, B3 c, C4 c, BA c, CD c,
[then]

decimal

: fill-ln ( col - )                     \ fill in short line to col
    bl swap col# - insert-chars ;

: ch-above ( - ch )                     \ return char above cursor
    dotline# 1 = if
        0 exit
    then
    col# c-up col# = if
        c-char
    else
        0
    then
    c-down
    -1 to prevcol ;

: ch-below ( - ch )                     \ return char below cursor
    dotline# #lines >= if
        0 exit
    then
    col# c-down col# = if
        c-char
    else
        0
    then
    c-up
    -1 to prevcol ;

: ch-left ( - ch )                      \ return char left of cursor
    col# 1- 0= if
        0 exit
    then
    c-left c-char c-right ;

: ch-right ( - ch )                     \ return char right of cursor
    col# 1- #cols < if
        c-right c-char c-left
    else
        0
    then ;

: legs ( ch -- indx )                   \ convert ch to indx
    0       ( ch num )
    begin
        dup 32 <
    while
        2dup draw-chars + c@ = if
            nip exit
        then
        1+
    repeat 2drop 0 ;

: draw-shape ( - indx )                 \ returns indx of char needed to draw shape
    ch-above legs leg-dn? 1 and
    ch-right legs leg-lf? 2 and or
    ch-below legs leg-up? 4 and or
    ch-left  legs leg-rt? 8 and or ;

: s/d ( indx -- ch )                    \ select single or double drawing char
    draw-style 2 = if
        16 +
    then draw-chars + c@ ;

in-editor

: d-at                                  \ draw single or double char
    draw-shape s/d ?dup if              \ get the proper draw char
[ Windows ] [if]    \ windows
        dup 5 < if
            half-chars + c@
        then
[then]
        col# 1- #cols < if
            delete-char
        then
        insert-char c-left
    then ;

in-hidden

: d_left ( ch - )
    col# 1- 0= if                       \ already in left col?
        drop exit                       \ can't go any further
    then
    -1 to prevcol
    c-left delete-char insert-char      \ replace ch to left
    d-at                                \ draw proper char here
    c-left d-at ;                       \ and then at left

in-editor

: d-l
    $0A s/d d_left ;                    \ shape lr

in-hidden

: d_right ( ch - )
    -1 to prevcol
    col# 1- #cols = if                  \ at eol?
        bl insert-char                  \ then must insert a space
    else
        c-right                         \ else just move right
    then
    col# 1- #cols < if                  \ not at eol?
        delete-char                     \ then delete a char
    then
    insert-char c-left                  \ replace ch
    c-left d-at                         \ back left draw
    c-right d-at ;                      \ then right again and draw

in-editor

: d-r
    $0A s/d d_right ;                   \ shape lr

in-hidden

: d_up ( ch - )
    dotline# 1 = if                     \ are we on top line?
        drop exit                       \ then can't go up
    then
    dotline# #lines 1+ = if             \ if on dummy line,
        insert-new-line                 \  insert an extra line
    then
    -1 to prevcol
    col# c-up fill-ln                   \ go up and fill in if line is too short
    col# 1- #cols < if                  \ if not at eol
        delete-char                     \ delete a char
    then
    insert-char c-left                  \ replace with supplied ch
    c-down d-at                         \ go down and draw the needed char here
    c-up d-at ;                         \ back up, draw and leave cursor there

in-editor

: d-u
    $05 s/d d_up ;                      \ shape ud

in-hidden

: d_down ( ch - )
    dotline# #lines 1+ = if             \ if on dummy line
        insert-new-line
    then
    -1 to prevcol
    col# c-down fill-ln
    col# 1- #cols < if
        delete-char                     \ delete if not at end of line
    then
    insert-char c-left                  \ replace with supplied ch
    c-up d-at                           \ replace char above with proper drawing char
    c-down d-at ;                       \ back down, and replace with proper drawing char

in-editor

: d-d
    $05 s/d d_down ;                    \ shape ud

variable drawkeys

>chain: mark-chain ( -- )               \ store current keychain state
  drawkeys @ , ;
>chain: prune-chain ( addr -- addr' )   \ restore keychain state
  @+ drawkeys ! ;

: enable-draw
    edkeys only-keys                    \ use editing key table
    drawkeys also-keys ;                \ add drawkeys to curkeys list

: disable-draw
    edkeys only-keys ;                  \ use editing key table

: toggle-draw
    draw-style 1+ to draw-style
    draw-style 3 = if
        0 to draw-style
        disable-draw
    else
        enable-draw
    then ;

