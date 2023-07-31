\ LOCATE  --  locate source of words                        17-04-00 21:06:57

\ The following source locater is required:
\ : src-location ( addr1 -- u1 addr2 )
\   Return source file name (addr2) and line number (u1) of word in
\   counted string (addr1); addr2=0 if file not found

in-hidden

\ view source file in which addr (counted string) is defined
: source-lookup ( addr -- flag )
    dup find if                     ( a xt )
        drop src-location ?dup if   ( u1 a' )
            view-file goto-line#
            true
        else
            drop false msg" Source file not found"
        then
    else
        2drop false msg" Word not found in search order"
    then ;

in-editor

: source-locate
    msg" Word to locate: "
    linein
    ed-#tib @ if
        ed-tib ed-#tib @ source!
        bl word source-lookup drop
    then ;

in-hidden

: dot-word ( - len )                    \ move word at dot to fname1
    dotofs dotln 2>r
    fname1 off                          \ null string in fname1
    begin                               \ backup through any white space
        dotofs
        c-char iswhite?
        dotofs dotlen = or and
    while
        c-left
    repeat
    begin                               \ to just before this word
        dotofs
        c-char iswhite? 0= and
    while
        c-left
    repeat
    c-char iswhite?
    dotofs dotlen <> and if             \ now to beginning of this word
        c-right
    then
    begin                               \ move word to token-buf
        c-char iswhite? 0=
        dotofs dotlen <> and
    while
        c-char fname1 $c+               \ concat one char
        c-right
    repeat
    2r> !dotln !dotofs
    fname1 c@ ;                         \ return length of word found

in-editor

: auto-locate   \ locate the source of the word under the cursor or ask if none
    dot-word if
        fname1 source-lookup if
            exit
        then
    then ;

also forth definitions
: locate  ( "name" -- )                 \ display the source of a word
    bl word dup if                      \ ignore if no word
        source-lookup drop
        edit                            \ switch to editor for viewing
    then ;
' locate alias l
previous definitions

: viewkeys ( -- )
  s" locate editor-key-bindings" evaluate ;

: edit-config-file ( -- )
  config-path if  config-path switch/read-file  then ;


\ Windows help file support

Windows [if]    \ windows

user32 import: WinHelp ( zlookup command zhelpfile hwnd -- )

create apiFile 256 allot  apiFile off   \ zstring pointing to windows help file

: winHelper ( zname zfile -- )          \ load zfile help file with zname as subject
  HELP_PARTIALKEY swap 0 WinHelp drop ;

: api ( "name" -- )
  apiFile zcount nip 0= abort" No apiFile specified "
  parse-word z>buf apiFile winHelper ;

: dotWinHelper ( zfile -- )
  dot-word if  fname1 count z>buf  else z" Contents"  then
  swap winHelper ;

: dotApi ( -- )  apiFile c@ if apiFile dotWinHelper then ;

[then]


0 [if]
: .src-files
    cr
    0 src-files     ( 0 hptr )
    begin
        dup
    while
        1 under+
        ." size = " dup cell+ @ 5 .r    \ size
        2 spaces
        dup cell+ cell+ count type cr   \ file name
        @                               \ next link
        over 20 mod 19 = if
            ." press key to continue " key drop cr
        then
    repeat
    2drop ;
[then]
