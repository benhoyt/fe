\ keybind.f  --  Key binding routines                       11-01-99 21:00:45

in-hidden

\ does anyone want more than three keys in a bound-key sequence?
3 value max-#keys                       \ maximum # of keys in a def

\ Key binding structure
0
cell field k>link                       \ link to next key binding
cell field k>code                       \ xt this key sequence is bound to
cell field k>#keys                      \ # of keys in this binding
max-#keys cells field k>keys            \ the actual scan codes of the keys
constant k-size

create inkeys max-#keys 1+ cells allot  \ temp space for incoming keys
    inkeys max-#keys 1+ cells erase

: clear-keys                            \ no keys present
    inkeys off ;
: add-key ( ekey -- )                   \ append key
    1 inkeys +!
    inkeys dup @ cells + ! ;
: thkey ( n -- key )                    \ get nth key
    cells inkeys + @ ;
: #keys ( -- n ) inkeys @ ;             \ get # of keys in array

: array= ( addr1 addr2 cnt -- flag )    \ compare two arrays of cells
    0 ?do               ( addr1 addr2 )
        over @ over @ <> if
            2drop unloop false exit
        then
        cell+ swap cell+
    loop
    2drop true ;

: ar=| ( addr1 addr2 -- flag )  \ compare counted arrays to length of shorter
    2dup @ swap @ min >r
    cell+ swap cell+ r> array= ;

: ar= ( addr1 addr2 -- flag )           \ compare counted arrays
    2dup @ swap @ min 1+ array= ;

: searchkeychain ( chainptr -- 0 | func flag ) \ search keychain for inkeys
    @                                   \  flag=1 partial match
    begin                               \  flag=-1 full match
        dup
    while
        dup k>#keys inkeys ar= if       \ full match?
            k>code @                    \ return func addr
            -1 exit                     \ return -1 = full match
        then
        dup k>#keys inkeys ar=| if      \ partial match?
            drop 0 1 exit               \ return 1 = partial match
        then
        k>link @                        \ check next key header
    repeat
;

in-editor

variable edkeys                         \ pointer to chain of keybindings for editor

>chain: mark-chain ( -- )                \ store current keychain state
  edkeys @ , ;
>chain: prune-chain ( addr -- addr' )    \ restore keychain state
  @+ edkeys ! ;

in-hidden

create keylist
    0 , 0 , 0 , 0 , 0 , edkeys , 0 ,    \ allow searching 6 key lists
keylist 3 cells + value curkeys         \ point to top key list stack

in-editor

\ Routines to handle keylist
: replace-keys ( chain -- )     \ make chain the first key list to search array
    curkeys ! ;
: only-keys ( chain -- )        \ make chain the only key list to search array
    keylist [ 3 cells ] literal + to curkeys
    replace-keys ;
: also-keys ( chain -- )                \ add chain to search array
    curkeys cell- to curkeys  replace-keys ;
: prev-keys                     \ remove the first key list from search array
    curkeys cell+ to curkeys ;

in-hidden

: findkey ( -- 0 | func flag )          \ search all keychains listed in curkeys
    curkeys                             \ flag=-1 full match
    begin                               \ flag=1 partial match
        dup @
    while
        dup @ searchkeychain ?dup if    \ exit if a bound key is found
            rot drop exit
        then
        cell+
    repeat
    drop false ;

\ Build key codes table
: make-key ( alt ctrl shft nrm -- )
    create , , , ,                  \ @@@ could add link to header for key name
    does> ( scp1 ... scpn n addr -- scp1 ... scpn+1 n+1 )
        swap 1+ ;

vocabulary key-table
also key-table definitions

: +Shift ( scpn n -- scpn' n ) [ 1 cells ] literal under+ ;
: +Ctrl ( scpn n -- scpn' n ) [ 2 cells ] literal under+ ;
: +Alt ( scpn n -- scpn' n ) [ 3 cells ] literal under+ ;

previous definitions

hex

DPMI [if]        \ BIOS enhanced keys

also key-table definitions

\  BIOS key code table
\   Alt  Ctrl Shft Nrm
    2900 EEEE 297E 2960 make-key `
    7800 EEEE 0221 0231 make-key 1
    7900 0300 0340 0332 make-key 2
    7A00 EEEE 0423 0433 make-key 3
    7B00 EEEE 0524 0534 make-key 4
    7C00 EEEE 0625 0635 make-key 5
    7D00 071E 075E 0736 make-key 6
    7E00 EEEE 0826 0837 make-key 7
    7F00 EEEE 092A 0938 make-key 8
    8000 EEEE 0A28 0A39 make-key 9
    8100 EEEE 0B29 0B30 make-key 0
    8200 0C1F 0C5F 0C2D make-key -
    8300 EEEE 0D2B 0D3D make-key =
    2B00 2B1C 2B7C 2B5C make-key \
    1A00 1A1B 1A7B 1A5B make-key [
    1B00 1B1D 1B7D 1B5D make-key ]
    2700 EEEE 273A 273B make-key ;
    2800 EEEE 2822 2827 make-key '
    3300 EEEE 333C 332C make-key ,
    3400 EEEE 343E 342E make-key .
    3500 EEEE 353F 352F make-key /
    1E00 1E01 1E41 1E61 make-key A
    3000 3002 3042 3062 make-key B
    2E00 2E03 2D43 2D63 make-key C
    2000 2004 2044 2064 make-key D
    1200 1205 1245 1265 make-key E
    2100 2106 2146 2166 make-key F
    2200 2207 2247 2267 make-key G
    2300 2308 2348 2368 make-key H
    1700 1709 1749 1769 make-key I
    2400 240A 244A 246A make-key J
    2500 250B 254B 256B make-key K
    2600 260C 264C 266C make-key L
    3200 320D 324D 326D make-key M
    3100 310E 314E 316E make-key N
    1800 180F 184F 186F make-key O
    1900 1910 1950 1970 make-key P
    1000 1011 1051 1071 make-key Q
    1300 1312 1352 1372 make-key R
    1F00 1F13 1F53 1F73 make-key S
    1400 1414 1454 1474 make-key T
    1600 1615 1655 1675 make-key U
    2F00 2F16 2F56 2F76 make-key V
    1100 1117 1157 1177 make-key W
    2D00 2D18 2D58 2D78 make-key X
    1500 1519 1559 1579 make-key Y
    2C00 2C1A 2C5A 2C7A make-key Z
    3920 3920 3920 3920 make-key Space
    0E00 0E7F 0E08 0E08 make-key BS
    A500 9400 0F00 0F09 make-key Tab
    0100 011B 011B 011B make-key Esc
    6800 5E00 5400 3B00 make-key F1
    6900 5F00 5500 3C00 make-key F2
    6A00 6000 5600 3D00 make-key F3
    6B00 6100 5700 3E00 make-key F4
    6C00 6200 5800 3F00 make-key F5
    6D00 6300 5900 4000 make-key F6
    6E00 6400 5A00 4100 make-key F7
    6F00 6500 5B00 4200 make-key F8
    7000 6600 5C00 4300 make-key F9
    7100 6700 5D00 4400 make-key F10
    8B00 8900 8700 8500 make-key F11
    8C00 8A00 8800 8600 make-key F12
    1C00 1C0A 1C0D 1C0D make-key Enter
    EEEE 9200 5230 5200 make-key Ins
    EEEE 7700 4737 4700 make-key Home
    EEEE 8400 4939 4900 make-key PgUp
    EEEE 7600 5133 5100 make-key PgDn
    EEEE 9300 532E 5300 make-key Del
    EEEE 7500 4F31 4F00 make-key End
    EEEE 8D00 4838 4800 make-key Up
    EEEE 9100 5032 5000 make-key Down
    EEEE 7300 4B34 4B00 make-key Left
    EEEE 7400 4D36 4D00 make-key Right
    EEEE 8F00 4C35 4C00 make-key K5
    A600 E00A E00D E00D make-key GEnter
    A200 92E0 52E0 52E0 make-key GIns
    9700 77E0 47E0 47E0 make-key GHome
    9900 84E0 49E0 49E0 make-key GPgUp
    A100 76E0 51E0 51E0 make-key GPgDn
    A300 93E0 53E0 53E0 make-key GDel
    9F00 75E0 4FE0 4FE0 make-key GEnd
    9800 8DE0 48E0 48E0 make-key GUp
    A000 91E0 50E0 50E0 make-key GDown
    9B00 73E0 4BE0 4BE0 make-key GLeft
    9D00 74E0 4DE0 4DE0 make-key GRight
    A400 9500 E02F E02F make-key G/
    3700 9600 372A 372A make-key G*
    4A00 8E00 4A2D 4A2D make-key G-
    4E00 9000 4E2B 4E2B make-key G+
    EEEE 7200 372A 372A make-key PrtScr
    EEEE 0000 EEEE EEEE make-key Break

previous definitions

[then]


Windows [if]    \ Windows console codes

also key-table definitions

\  Windows key code table
\   Alt  Ctrl Shft Nrm
    A904 A902 297E 2960 make-key `
    8204 8202 0221 0231 make-key 1
    8304 0300 0340 0332 make-key 2
    8404 8402 0423 0433 make-key 3
    8504 8502 0524 0534 make-key 4
    8604 8602 0625 0635 make-key 5
    8704 071E 075E 0736 make-key 6
    8804 8802 0826 0837 make-key 7
    8904 8902 092A 0938 make-key 8
    8A04 8A02 0A28 0A39 make-key 9
    8B04 8B02 0B29 0B30 make-key 0
    8C04 0C1F 0C5F 0C2D make-key -
    8D04 8D02 0D2B 0D3D make-key =
    AB04 2B1C 2B7C 2B5C make-key \
    9A04 1A1B 1A7B 1A5B make-key [
    9B04 1B1D 1B7D 1B5D make-key ]
    A704 A702 273A 273B make-key ;
    A804 A802 2822 2827 make-key '
    B304 B302 333C 332C make-key ,
    B404 B402 343E 342E make-key .
    B504 B502 353F 352F make-key /
    9E04 1E01 1E41 1E61 make-key A
    B004 3002 3042 3062 make-key B
    AE04 2E03 2E43 2E63 make-key C
    A004 2004 2044 2064 make-key D
    9204 1205 1245 1265 make-key E
    A104 2106 2146 2166 make-key F
    A204 2207 2247 2267 make-key G
    A304 2308 2348 2368 make-key H
    9704 1709 1749 1769 make-key I
    A404 240A 244A 246A make-key J
    A504 250B 254B 256B make-key K
    A604 260C 264C 266C make-key L
    B204 320D 324D 326D make-key M
    B104 310E 314E 316E make-key N
    9804 180F 184F 186F make-key O
    9904 1910 1950 1970 make-key P
    9004 1011 1051 1071 make-key Q
    9304 1312 1352 1372 make-key R
    9F04 1F13 1F53 1F73 make-key S
    9404 1414 1454 1474 make-key T
    9604 1615 1655 1675 make-key U
    AF04 2F16 2F56 2F76 make-key V
    9104 1117 1157 1177 make-key W
    AD04 2D18 2D58 2D78 make-key X
    9504 1519 1559 1579 make-key Y
    AC04 2C1A 2C5A 2C7A make-key Z
    EEEE 3920 3920 3920 make-key Space
    8E04 0E7F 0E08 0E08 make-key BS
    EEEE 8F02 8F01 0F09 make-key Tab
    EEEE EEEE 8101 011B make-key Esc
    BB04 BB02 BB01 BB00 make-key F1
    BC04 BC02 BC01 BC00 make-key F2
    BD04 BD02 BD01 BD00 make-key F3
    BE04 BE02 BE01 BE00 make-key F4
    BF04 BF02 BF01 BF00 make-key F5
    C004 C002 C001 C000 make-key F6
    C104 C102 C101 C100 make-key F7
    C204 C202 C201 C200 make-key F8
    C304 C302 C301 C300 make-key F9
    C404 C402 C401 C400 make-key F10
    D704 D702 D701 D700 make-key F11
    D804 D802 D801 D800 make-key F12
    EEEE 1C0A 1C0D 1C0D make-key Enter
    D204 D202 D201 D200 make-key Ins
    C704 C702 C701 C700 make-key Home
    C904 C902 C901 C900 make-key PgUp
    D104 D102 D101 D100 make-key PgDn
    D304 D302 D301 D300 make-key Del
    CF04 CF02 CF01 CF00 make-key End
    C804 C802 C801 C800 make-key Up
    D004 D002 D001 D000 make-key Down
    CB04 CB02 CB01 CB00 make-key Left
    CD04 CD02 CD01 CD00 make-key Right
    CC04 CC02 CC01 CC00 make-key K5
    9C14 1C0A 1C0D 1C0D make-key GEnter
    D214 D212 D211 D210 make-key GIns
    C714 C712 C711 C710 make-key GHome
    C914 C912 C911 C910 make-key GPgUp
    D114 D112 D111 D110 make-key GPgDn
    D314 D312 D311 D310 make-key GDel
    CF14 CF12 CF11 CF10 make-key GEnd
    C814 C812 C811 C810 make-key GUp
    D014 D012 D011 D010 make-key GDown
    CB14 CB12 CB11 CB10 make-key GLeft
    CD14 CD12 CD11 CD10 make-key GRight
    B514 B512 353F 352F make-key G/
    EEEE B702 EEEE 372A make-key G*
    CA04 CA02 4A2D 4A2D make-key G-
    CE04 CE02 4E2B 4E2B make-key G+
    EEEE B712 372A EEEE make-key PrtScr
    EEEE EEEE EEEE EEEE make-key Break

previous definitions

[then]

Linux [if]    \ Linux with US keyboard and BS = 7F

also key-table definitions
warnings off                            \ since ' + - etc. are already defined
\   ASCII key codes; you may have to modify this table to suit your keyboard
\   Alt  Ctrl Shft Nrm
    00E0 0000 007E 0060 make-key `
    00B1 EEEE 0021 0031 make-key 1
    00B2 0000 0040 0032 make-key 2
    00B3 001B 0023 0033 make-key 3
    00B4 001C 0024 0034 make-key 4
    00B5 001D 0025 0035 make-key 5
    00B6 001E 005E 0036 make-key 6
    00B7 001F 0026 0037 make-key 7
    00B8 007F 002A 0038 make-key 8
    00B9 EEEE 0028 0039 make-key 9
    00B0 EEEE 0029 0030 make-key 0
    00AD 001F 005F 002D make-key -
    00BD EEEE 002B 003D make-key =
    00DC 001C 007C 005C make-key \
    00DB 001B 007B 005B make-key [
    00DD 001D 007D 005D make-key ]
    00BB EEEE 003A 003B make-key ;
    00A7 0007 0022 0027 make-key '
    00AC EEEE 003C 002C make-key ,
    00AE EEEE 003E 002E make-key .
    00AF 007F 003F 002F make-key /
    00E1 0001 0041 0061 make-key A
    00E2 0002 0042 0062 make-key B
    00E3 0003 0043 0063 make-key C
    00E4 0004 0044 0064 make-key D
    00E5 0005 0045 0065 make-key E
    00E6 0006 0046 0066 make-key F
    00E7 0007 0047 0067 make-key G
    00E8 0008 0048 0068 make-key H
    00E9 0009 0049 0069 make-key I
    00EA 000A 004A 006A make-key J
    00EB 000B 004B 006B make-key K
    00EC 000C 004C 006C make-key L
    00ED 000D 004D 006D make-key M
    00EE 000E 004E 006E make-key N
    00EF 000F 004F 006F make-key O
    00F0 0010 0050 0070 make-key P
    00F1 0011 0051 0071 make-key Q
    00F2 0012 0052 0072 make-key R
    00F3 0013 0053 0073 make-key S
    00F4 0014 0054 0074 make-key T
    00F5 0015 0055 0075 make-key U
    00F6 0016 0056 0076 make-key V
    00F7 0017 0057 0077 make-key W
    00F8 0018 0058 0078 make-key X
    00F9 0019 0059 0079 make-key Y
    00FA 001A 005A 007A make-key Z
    00A0 0000 0020 0020 make-key Space
    0088 007F 0008 007F make-key BS
    0089 0009 0009 0009 make-key Tab
    009B 001B 001B 001B make-key Esc
    008D 000D 000D 000D make-key Enter
    0300 0300 0300 0300 make-key Home
    0301 0301 0301 0301 make-key Ins
    0302 0302 0302 0302 make-key Del
    0303 0303 0303 0303 make-key End
    0304 0304 0304 0304 make-key PgUp
    0305 0305 0305 0305 make-key PgDn
    EEEE 0306 0306 0306 make-key Up
    0307 0307 0307 0307 make-key Down
    EEEE 0308 0308 0308 make-key Right
    EEEE 0309 0309 0309 make-key Left
    EEEE EEEE 020E 0201 make-key F1
    EEEE EEEE 020F 0202 make-key F2
    EEEE EEEE 0211 0203 make-key F3
    EEEE EEEE 0212 0204 make-key F4
    EEEE EEEE 0214 0205 make-key F5
    EEEE EEEE 0215 0206 make-key F6
    EEEE EEEE 0216 0207 make-key F7
    EEEE EEEE 0217 0208 make-key F8
    EEEE EEEE EEEE 0209 make-key F9
    EEEE EEEE EEEE 020A make-key F10
    EEEE EEEE EEEE 020C make-key F11
    EEEE EEEE EEEE 020D make-key F12
    CC04 CC02 4C35 CC00 make-key K5
    9C14 1C0A 1C0D 1C0D make-key GEnter
    D214 D212 D211 D210 make-key GIns
    C714 C712 C711 C710 make-key GHome
    C914 C912 C911 C910 make-key GPgUp
    D114 D112 D111 D110 make-key GPgDn
    D314 D312 D311 D310 make-key GDel
    CF14 CF12 CF11 CF10 make-key GEnd
    C814 C812 C811 C810 make-key GUp
    D014 D012 D011 D010 make-key GDown
    CB14 CB12 CB11 CB10 make-key GLeft
    CD14 CD12 CD11 CD10 make-key GRight
    B514 B512 353F 352F make-key G/
    EEEE B702 EEEE 372A make-key G*
    CA04 CA02 4A2D 4A2D make-key G-
    CE04 CE02 4E2B 4E2B make-key G+
    EEEE B712 372A EEEE make-key PrtScr
    EEEE EEEE EEEE EEEE make-key Break
    00CF 00CF 00CF 00CF make-key Prefix     { prefix for keys like Ctrl-Left in linux - at least in putty - berwyn }
previous definitions
warnings on
[then]

decimal

\ Define key bindings
\ Example:
\   binding edkeys
\       ' c-eol bind: Q +Ctrl D +Ctrl ,keys
\   binds the two key sequence Ctrl+Q Ctrl+D to the function c-eol
\   and links this binding to the edkeys chain
\   for complete example see bindings.f

0 value &chain                          \ chain to which keys are being bound

in-editor

: binding ( "name" -- )                 \ set pointer to chain of bound keys
    ' >body to &chain ;

: bind: ( func -- 0 )                   \ bind the function to following keys
    also key-table
    align here &chain @ , &chain ! ,          \ compile link and func
    0 ;

: ,keys ( scp1 scp2 ... scpn n -- )     \ compile scan codes
    previous
    dup ,                               \ # of keys
    dup >r
    begin
        ?dup
    while
        1- swap @       ( scp1 scp2 ... i sci  R: n )
        over            ( scp1 scp2 ... i sci i  R: n )
        cells here + !                  \ store scan codes in reverse order
    repeat
    r> cells allot ;
