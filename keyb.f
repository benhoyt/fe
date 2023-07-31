\ keyb.f  --  key binding

0 [if]

Bind a key to a deferred word whose name field is the byte sequence for the
key sequence to be bound.

    e.g. Ctrl+Q-Ctrl+D = $04 $11 $10 $04 $20  where $04 is the length

    a header can be defined as  s" \x11\x10\x04\x20" (header,)

[then]

: keyheader ( addr u -- )               \ define header from string
    (header,) reveal ;

: deferkey ( addr u xt -- )             \ like defer but takes a string and xt
    keyheader  align !hlc-xt
    postpone (defer)                    \ name E( i*x -- j*x )
    w, ;

: keyname, ( addr u -- )
    s, ;

: c-append ( c addr -- )
    >r sp@ 1 r> append drop ;

0 value cur-depth

: bind ( -- )
    depth to cur-depth ;

: to> ( i*x -- )
    256 s-buf-mem >r
    r@ off
    depth cur-depth -   ( i*x i R: a)
    begin
        ?dup
    while
        swap dup $FF and r@ c-append
        8 rshift $FF and r@ c-append
        1-
    repeat r> count     ( a u)
    ' deferkey

\ Usage:   bind $2004 $1011 to> c-eol   \ keys listed backwards

$1E61 constant a
$1E41 constant A
$1E01 constant Ctrl+a
$9E04 constant Alt+a
$9E03 constant Ctrl+Shift+a
$9E06 constant Ctrl+Alt+a
$9E05 constant Shift+Alt+a
$9E07 constant Ctrl+Shift+Alt+a

$BB00 constant F1
$BB02 constant Ctrl+F1
$BB01 constant Shift+F1
????? constant Alt+F1
$BB03 constant Ctrl+Shift+F1
$BB06 constant Ctrl+Alt+F1
$BB05 constant Shift+Alt+F1
$BB07 constant Ctrl+Shift+Alt+F1

\ does anyone want more than 5 keys in a bound-key sequence?
5 value max-#keys                       \ maximum # of keys in a key binding sequence

create inkeys max-#keys 2* 1+ allot     \ temp space for incoming keys
    inkeys off

: clear-keys                            \ no keys present
    inkeys off ;

: add-key ( ekey -- )                   \ append key
    1 inkeys c+!
    dup $FF and inkeys c-append
    8 rshift $FF and inkeys c-append ;

: thkey ( n -- key )                    \ get nth key
    2* inkeys + w@ ;

: #keys ( -- n )                        \ get # of keys in array
    inkeys c@ 2/ ;

\ get-key inputs one key and adds it to inkeys, then searches the current keybinding context
\ if found, clear-keys and return func and true
\ if not found and if there is only 1 key in inkeys, return key and 1
\ else return 0

: get-key ( -- 0 | func -1 | key 1 )    \ process multiple key input
    clear-keys
    begin
        ed-ekey add-key                 \ append key
        findkey ?dup if
            -1 = if                     \ full match?
                -1 exit
            else
                drop                    \ no, so loop again
            then
        else
            #keys 1 = if                \ not bound, so check only one key?
                1 thkey ekey>char
                over bl >= and if
                    1 exit
                else
                    drop
                then
            then
            0 exit                      \ invalid key sequence
        then
    again
;

\ Nrm  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
\        Esc 1  2  3  4  5  6  7  8  9  0  -  = BS Tab
\     -1 1B 31 32 33 34 35 36 37 38 39 30 2D 3D 08 09

\ Nrm 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
\      q  w  e  r  t  y  u  i  o  p  [  ] Ent    a  s
\     71 77 65 72 74 79 75 69 6F 70 5B 5D 0D -1 61 73

\ Nrm 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F


\  Windows key code table
\   Ctrl Shft Nrm
    EEEE 8101 011B make-key Esc
    8202 0221 0231 make-key ! 1
    0300 0340 0332 make-key @ 2
    8402 0423 0433 make-key # 3
    8502 0524 0534 make-key $ 4
    8602 0625 0635 make-key % 5
    071E 075E 0736 make-key ^ 6
    8802 0826 0837 make-key & 7
    8902 092A 0938 make-key * 8
    8A02 0A28 0A39 make-key ( 9
    8B02 0B29 0B30 make-key ) 0
    0C1F 0C5F 0C2D make-key _ -
    8D02 0D2B 0D3D make-key + =
    0E7F 0E08 0E08 make-key BS
    8F02 8F01 0F09 make-key Tab
    1011 1051 1071 make-key Q q
    1117 1157 1177 make-key W w
    1205 1245 1265 make-key E e
    1312 1352 1372 make-key R r
    1414 1454 1474 make-key T t
    1519 1559 1579 make-key Y y
    1615 1655 1675 make-key U u
    1709 1749 1769 make-key I i
    180F 184F 186F make-key O o
    1910 1950 1970 make-key P p
    1A1B 1A7B 1A5B make-key { [
    1B1D 1B7D 1B5D make-key } ]
    1C0A 1C0D 1C0D make-key Enter
    1C0A 1C0D 1C0D make-key GEnter
    1E01 1E41 1E61 make-key A a
    1F13 1F53 1F73 make-key S s
    2004 2044 2064 make-key D d
    2106 2146 2166 make-key F f
    2207 2247 2267 make-key G g
    2308 2348 2368 make-key H h
    240A 244A 246A make-key J j
    250B 254B 256B make-key K k
    260C 264C 266C make-key L l
    A702 273A 273B make-key : ;
    A802 2822 2827 make-key " '
    A902 297E 2960 make-key ~ `
    2B1C 2B7C 2B5C make-key | \
    2C1A 2C5A 2C7A make-key Z z
    2D18 2D58 2D78 make-key X x
    2E03 2E43 2E63 make-key C c
    2F16 2F56 2F76 make-key V v
    3002 3042 3062 make-key B b
    310E 314E 316E make-key N n
    320D 324D 326D make-key M m
    B302 333C 332C make-key < ,
    B402 343E 342E make-key > .
    B502 353F 352F make-key ? /
    B512 353F 352F make-key G? G/
    B702 EEEE 372A make-key G*
    3920 3920 3920 make-key Space

    BB02 BB01 BB00 make-key F1
    BC02 BC01 BC00 make-key F2
    BD02 BD01 BD00 make-key F3
    BE02 BE01 BE00 make-key F4
    BF02 BF01 BF00 make-key F5
    C002 C001 C000 make-key F6
    C102 C101 C100 make-key F7
    C202 C201 C200 make-key F8
    C302 C301 C300 make-key F9
    C402 C401 C400 make-key F10

    C702 C701 C700 make-key Home
    C802 C801 C800 make-key Up
    C902 C901 C900 make-key PgUp
    CA02 4A2D 4A2D make-key G-
    CB02 CB01 CB00 make-key Left
    CC02 CC01 CC00 make-key K5
    CD02 CD01 CD00 make-key Right
    CE02 4E2B 4E2B make-key G+
    CF02 CF01 CF00 make-key End
    D002 D001 D000 make-key Down
    D102 D101 D100 make-key PgDn
    D202 D201 D200 make-key Ins
    D302 D301 D300 make-key Del

    C712 C711 C710 make-key GHome
    C812 C811 C810 make-key GUp
    C912 C911 C910 make-key GPgUp
    CB12 CB11 CB10 make-key GLeft
    CD12 CD11 CD10 make-key GRight
    CF12 CF11 CF10 make-key GEnd
    D012 D011 D010 make-key GDown
    D112 D111 D110 make-key GPgDn
    D212 D211 D210 make-key GIns
    D312 D311 D310 make-key GDel

    D702 D701 D700 make-key F11
    D802 D801 D800 make-key F12




Esc
!
1
@
2
#
3
$
4
%
5
^
6
&
7
*
8
(
9
)
0
_
-
+
=
BS
Tab
Q
q
W
w
E
e
R
r
T
t
Y
y
U
u
I
i
O
o
P
p
{
[
}
]
Enter
GEnter
A
a
S
s
D
d
F
f
G
g
H
h
J
j
K
k
L
l
:
;
"
'
~
`
|
\
Z
z
X
x
C
c
V
v
B
b
N
n
M
m
<
,
>
.
?
/
G?
G/
G*
Space

