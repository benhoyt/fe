\ NONSTD  --  non-standard routines                         01-03-99 09:14:26

0 [if]

-------------------------------------------------------------------------------
|   The purpose of this file is to explain and document non-standard          |
|   routines used in FE.                                                      |
|                                                                             |
|   Routines needed to run on various systems are defined in the system       |
|   include files: bens.f os2.f gfe.f ife.f                                   |
|                                                                             |
|   Options may be compiled that require various non-standard system          |
|   routines. The options are: allow-prog-name allow-expand-path              |
|   allow-wild-cards allow-dir-creates allow-shell allow-defer-accept         |
|   allow-colour                                                              |
|                                                                             |
|   A list of the non-standard routines required for the various options      |
|   is given below:                                                           |
|                                                                             |
|   isearch      \ should be in code for faster text searching                |
|   screen-size set-colour type-chars init-keyboard                           |
|   warnings source! command-line source-line#                                |
|   shell get-full-path get-prog-name get-prog-path                           |
|   fa-nrm find-first-file find-next-file ff-name                             |
|   create-dir delete-dir                                                     |
|   accept              \ is it deferrable?                                   |
|   'cold               \ for auto starting of editor                         |
|                                                                             |
|   Other non-standard routines I use are defined here preceded by need:      |
|   Make sure any of these already defined in your system have the same       |
|   meaning.                                                                  |
-------------------------------------------------------------------------------

[then]

\ need: compiles a definition unless it is already present
\ if the word is already defined in your system, carefully check to make sure
\ that the definition is semantically identical
: need:
    >in @ >r  bl word  r> >in !
    find nip if
        postpone [else]                 \ is this ANS?
    else
        :
    then
;

\ ---------------------------------------------------------------------------
\ Compiler operations
\ ---------------------------------------------------------------------------

need: alias ( xt -- )                   \ different name for same thing
    create ,
    does> @ execute ;
[then]

need: noop
    ;
[then]

need: defer ( "name" -- )               \ execution vector
    create ['] noop ,
    does> @ execute ;
[then]

need: is ( xt "name" -- )               \ like 'to' but for defer words
    ' state @ if
        postpone literal postpone >body postpone !
    else
        >body !
    then ;  immediate
[then]

need: is? ( defer-xt -- is-xt )
    >body @ ;
[then]

need: field ( ofs size -- ofs' )        \ define structures (simple)
    over create , +
    does> ( addr -- addr+ofs )
        @ + ;
[then]

need: parse-word ( "xxx" -- addr cnt )
    bl parse    ( addr cnt )
    begin
        over c@ bl =
        over 0> and
    while
        1 /string
    repeat ;
[then]

\ ---------------------------------------------------------------------------
\ Computation and logical operations
\ ---------------------------------------------------------------------------

hex
need: toupper ( char1 -- char2 )        \ convert char1 to upper case
    dup [char] a [char] { within if
        DF and
    endif ;
[then]

need: tolower ( char1 -- char2 )        \ convert char1 to lower case
    dup [char] A [char] [ within if
        20 or
    endif ;
[then]

decimal

need: isalpha? ( char -- flag )         \ test for alpha char
    toupper [char] A [char] [ within ;
[then]

need: iswhite? ( char -- flag )         \ test for white space char
    dup bl = swap 9 = or ;
[then]

need: -rot ( x1 x2 x3 -- x3 x1 x2 )     \ rotate top item down to third
    rot rot ;
[then]

need: on ( addr -- )                    \ set variable
    true swap ! ;
[then]

need: off ( addr -- )                   \ reset variable
    false swap ! ;
[then]

need: >= ( n1 n2 -- flag )
    - dup 0= swap 0> or ;
[then]

need: <= ( n1 n2 -- flag )
    - dup 0= swap 0< or ;
[then]

need: 0<= ( n -- flag )
    dup 0= swap 0< or ;
[then]

need: 2+ ( n1 -- n2 )                   \ add 2 to n1
    2 + ;
[then]

need: 2- ( n1 -- n2 )                   \ subtract 2 from n1
    2 - ;
[then]

need: under+ ( n1 n2 n3 -- n1+n3 n2 )   \ add n3 underneath
    rot + swap ;
[then]

need: cell ( -- u )                     \ size of one cell
    1 cells ;
[then]

need: cell- ( u1 -- u2 )                \ back up one cell
    cell - ;
[then]

need: c+! ( n addr -- )                 \ add n to byte at addr
    dup c@ under+ c! ;
[then]

need: $move ( src dest -- )             \ move counted string src to dest
    over c@ 1+ move ;
[then]

need: $c+ ( char dest -- )              \ add char to end of dest string
    1 over c+!                          \ increment count of dest
    count + 1- c! ;
[then]

need: bounds ( addr cnt -- start end )  \ ready for do ... loop
    over + swap ;
[then]

need: $toupper ( $str -- )              \ convert string to upper case
    count bounds ?do
        i c@ toupper  i c!
    loop
;
[then]

need: $icmp ( src dest - l/e/g )        \ compare two counted strings
    >r count r> count icompare ;
[then]

need: place ( c-addr cnt dest -- )  \ place a string at dest as counted string
    2dup 2>r  char+ swap chars move  2r> c! ;
[then]

need: append ( addr cnt dest -- )       \ cat string to counted dest string
    2dup 2>r                ( addr cnt dest R: cnt dest )
    count + swap chars move ( R: cnt dest )
    2r> c+! ;
[then]

need: s,  ( c-addr u -- )          \ compile string as counted string
    here  over 1+ chars allot  place ;
[then]

need: ," ( "..." -- )                   \ compile a counted string
    [char] " parse s, ;
[then]

\ skip all chars in string c-addr1:u1 equal to char
\ if not equal found return string c-addr2 u2
need: skip ( c-addr1 u1 char -- c-addr2 u2 )
    >r
    begin
        dup
    while
        over c@ r@ =
    while
        1 /string
    repeat then
    r> drop ;
[then]

\ skip all chars in string c-addr1:u1 not equal to char
\ if equal found return string c-addr2 u2
need: scan ( c-addr1 u1 char -- c-addr2 u2 )
    >r
    begin
        dup
    while
        over c@ r@ <>
    while
        1 /string
    repeat then
    r> drop ;
[then]

\ skip all chars in string c-addr1:u1 not equal to char from right end;
\ if found return string c-addr2:u2 including char
\ else u2 is 0 and c-addr2 is c-addr1+u1
need: -scan ( c-addr1 u1 char -- c-addr2 u2 )
    -rot tuck + 0 rot 0 ?do     ( chr adr u )
        -1 /string over c@ 3 pick = if
            rot drop unloop exit
        endif
    loop
    + nip 0 ;
[then]

char / value slch

need: /file.ext ( path len -- fname cnt )   \ return file name string
    2dup slch -scan dup if
        1 /string 2swap
    else
        2drop 2dup ': -scan dup if      \ only for MSDOS
            1 /string 2swap
        then
    then
    2drop ;
[then]

need: /ext ( path len -- ext cnt )      \ return extension string
    [char] . -scan
    dup if
        over 1+ c@ slch = if            \ discard "./xyz"
            2drop 0 0
        then
    then ;
[then]

need: /path ( path len -- path len' ) \ return only the path [& drive]
    2dup /file.ext nip - ;
[then]

need: incr ( a-addr -- )                \ add 1 to cell at a-addr
    1 swap +! ;
[then]

need: decr ( a-addr -- )                \ substract 1 from cell at a-addr
    -1 swap +! ;
[then]

need: set-bits ( x a-addr -- )          \ or x to cell at a-addr
    dup @ rot or swap ! ;
[then]

need: toggle-bits ( x a-addr -- )       \ xor x to cell at a-addr
    dup @ rot xor swap ! ;
[then]

need: reset-bits ( x a-addr -- )        \ reset bits in cell at a-addr
    dup @ rot invert and swap ! ;       \  which are 1 bits in x
[then]

need: test-bits ( x a-addr -- x )       \ test bits in cell at a-addr
    @ and ;                             \  using mask x
[then]

\ ---------------------------------------------------------------------------
\ OS System operations
\ ---------------------------------------------------------------------------

need: mfree  ( a-addr -- )              \ free memory and throw if error
    free throw ;
[then]

need: mallocate ( u -- a-addr )         \ allocate and throw if error
    allocate throw ;
[then]

need: bell ( -- )                       \ ring the console bell
    7 emit ;
[then]

need: screen-size ( -- cols rows )
    80 25 ;                             \ default screen size
[then]

\ If colour is not available, disallow setting
allow-colour 0= [if]    \ no colour
: set-colour ( clr -- )
    drop ;
[then]

\ ansi colour routines
allow-colour 1 = [if]
\   foregnd     colour      backgnd
\   30          black       40
\   31          red         41
\   32          green       42
\   33          brown       43
\   34          blue        44
\   35          magenta     45
\   36          cyan        46
\   37          white       47
\   attribute
\   0   off
\   1   bold
\   2   dim
\   4   underline
\   5   blink
\   7   reverse
\   8   invisible

create ans-clrs char 0 c, char 4 c, char 2 c, char 6 c,
                char 1 c, char 5 c, char 3 c, char 7 c,

: esc[0;  27 emit ." [0;" ;
: ;m  ." ;m" ;
: 1;  ." 1;" ;

: low-digit ( clr -- )
    7 and ans-clrs + c@ emit ;
: atr+digit ( clr -- )
    15 and [char] 3 emit  dup low-digit
    [char] ; emit
    8 and if  1;  then ;
: bg-clr ( clr -- )
    [char] 4 emit
    4 rshift low-digit ;
: set-colour ( clr -- )                 \ corresponding ansi colour
    esc[0; dup atr+digit
    bg-clr  [char] m emit ;
[then]

allow-colour 2 = [if]   \ user colour
\ I use the PC hardware colours as is
[then]
