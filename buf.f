\ BUF  --  Buffer structure and routines                    11-01-99 20:59:42

: byte 1 ;

in-hidden

\ Buffer structure: doubly linked list
dl-links-size
cell field b>name                       \ ptr to buffer name string
cell field b>wind                       \ ptr to window displaying this buffer
cell field b>ln-array                   \ ptr to array of line pointers
cell field b>ln-array-size              \ # cells in lp array
cell field b>#lines                     \ # of lines in buffer
cell field b>top#                       \ # of line at top of screen
cell field b>dot#                       \ # of dot line
cell field b>dotofs                     \ dot offset
cell field b>windofs                    \ col offset of window text
cell field b>mark#                      \ # of mark line
cell field b>markofs                    \ mark offset
cell field b>r-margin                   \ right margin for wrap
cell field b>l-margin                   \ left margin for wrap
byte field b>flags                      \ buffer flags, defined below
byte field b>tabsize                    \ tab size for this buffer
constant b-size                         \ buffer structure size

hex
\ Buffer flags, bits in b>flags
    1 constant bf-changed               \ buffer changed
    2 constant bf-show-marked           \ mark showing
    4 constant bf-r/o                   \ read only
   10 constant bf-auto-indent           \ auto indent
   20 constant bf-backup                \ need to backup
                                        \   i.e. changed since last backup
   21 constant bf-modified              \ both b_changed and b_backup bits
   40 constant bf-wrap                  \ word wrap
   80 constant bf-overwrite             \ overwrite
decimal

0 value curbuf                          \ currently active buffer

\ access data in curbuf fields
: bname ( -- ptr ) curbuf b>name @ ;
: topln ( -- ln ) curbuf b>top# @ ;
: dotln ( -- ln ) curbuf b>dot# @ ;
: dotofs ( -- ofs ) curbuf b>dotofs @ ;
: windofs ( -- n ) curbuf b>windofs @ ;
: markln ( -- ln ) curbuf b>mark# @ ;
: markofs ( -- ofs ) curbuf b>markofs @ ;
: r-margin ( -- ofs ) curbuf b>r-margin @ ;
: l-margin ( -- ofs ) curbuf b>l-margin @ ;
: tabsize ( -- n ) curbuf b>tabsize c@ ;
: ln-array ( -- ptr ) curbuf b>ln-array @ ;
: ln-array-size ( -- n ) curbuf b>ln-array-size @ ;
: #lines ( -- n ) curbuf b>#lines @ ;

\ store data to fields in curbuf
: !bname ( ptr -- ) curbuf b>name ! ;
: !topln ( ln -- ) curbuf b>top# ! ;
: !dotln ( ln -- ) curbuf b>dot# ! ;
: !dotofs ( ofs -- ) curbuf b>dotofs ! ;
: !windofs ( n -- ) curbuf b>windofs ! ;
: !markln ( ln -- ) curbuf b>mark# ! ;
: !markofs ( ofs -- ) curbuf b>markofs ! ;
: !r-margin ( ofs -- ) curbuf b>r-margin ! ;
: !l-margin ( ofs -- ) curbuf b>l-margin ! ;
: !tabsize ( n -- ) curbuf b>tabsize c! ;
: !ln-array ( ptr -- ) curbuf b>ln-array ! ;
: !ln-array-size ( n -- ) curbuf b>ln-array-size ! ;
: !#lines ( n -- ) curbuf b>#lines ! ;

\ The line pointer array has one entry for each line with a dummy at the end
\ Each entry consists of 2 cells: a pointer to the line & length of the line

: nth-l ( n -- l ) cells 2* ln-array + ; \ ptr to nth line entry
: nth-lp ( n -- lp ) nth-l @ ;          \ ptr to text of nth line
: !nth-lp ( ptr n -- ) nth-l ! ;
: nth-len ( n -- len ) nth-l cell+ @ ;  \ length of nth line
: !nth-len ( cnt n -- ) nth-l cell+ ! ;
: nth-str ( n -- addr cnt ) dup nth-lp swap nth-len ; \ addr and length of line

: dotlp ( -- ptr ) dotln nth-lp ;       \ addr of dot line
: !dotlp ( ptr -- ) dotln !nth-lp ;
: dotpos ( -- ptr ofs ) dotlp dotofs ;  \ addr of dot line and offset of dot
: dotptr ( -- ptr ) dotpos + ;          \ addr of cursor in dot line
: dotlen ( -- n ) dotln nth-len ;       \ length of dot line
: !dotlen ( n -- ) dotln !nth-len ;
: dot-#toeol ( -- n ) dotlen dotofs - ; \ # chars to end of dot line
: dot-tail ( -- ptr len ) dotptr dot-#toeol ; \ string from cursor to end of line
: dot-line ( -- ptr len ) dotln nth-str ; \ string of whole dot line


\ Empty lines point to a dummy address
create empty-line end-line-char c,      \ a valid address for empty lines,
                                        \ don't actually need any data here

: make-dummy-line                       \ =empty buffer
    empty-line 0 !nth-lp                \ 0th line is empty
    0 0 !nth-len ;

\ allocate lines in increments of l-incr # bytes
8 constant l-incr                       \ must be power of two
l-incr 1- invert constant l-incr-mask

: prev-incr ( len -- lcut )             \ previous l-incr boundary
    l-incr-mask and ;

: alloc-size ( len -- asize )           \ allocation size for len
    l-incr 1- + prev-incr ;

: lmalloc ( cnt -- ptr )                \ allocate mem for line of cnt bytes
    ?dup if
        alloc-size mallocate
    else
        empty-line                      \ empty line
    then ;

: lmfree ( ptr -- )                     \ free mem for line
    dup empty-line = if
        drop                            \ don't free the dummy
    else
        mfree
    then ;

: b-free-lines                          \ free text lines
    #lines 0 ?do
        i nth-lp lmfree
    loop ;

: b-mfree                               \ free lines and buffer name
    b-free-lines
    ln-array mfree
    bname mfree ;

: b-destroy                             \ destroy curbuf
    b-mfree
    curbuf mfree ;                      \ free the buffer structure

: b-create ( -- bp )                    \ create a buffer
    b-size mallocate                    \ allocate the space
    dup b-size erase                    \ all fields initially 0
    bf-auto-indent over b>flags auto-indent if \ then set auto-indent
        set-bits
    else
        reset-bits
    then
    read-tabsize over b>tabsize c!      \ initial tabsize
    default-right-margin 1- over b>r-margin ! \ initial margins for wrap
    default-left-margin 1- over b>l-margin !
    dup dl-self ;                       \ link buffer to itself

: _create-buffer ( name -- bp )     \ make a named buffer, name=counted string
    b-create >r                         \ get buffer space
    dup c@ 1+ mallocate dup             \ get space for file name string
    r@ b>name !                         \ point to string space
    $move                               \ copy file name string
    r> ;                                \ return ptr to buffer

\ Dummy buffer for head of doubly linked list
: dummy-buffer ( -- bp )                \ create a dummy buffer
    dl-links-size mallocate             \ allocate the space
    dup dl-self ;                       \ link buffer to itself

0 value buffer-head                     \ head of text buffer list
0 value udb-head                        \ head of undelete buffer list
0 value paste-head                      \ head of paste buffer list

\ do this once at program start-up
: init-buffers
    0 to curbuf
    c" Head-Buffer" _create-buffer to buffer-head
    dummy-buffer to udb-head
    dummy-buffer to paste-head ;

\ increment line pointer array by this # of lines
1024 value min-text-lines
    \ 1024 is enough for about 32K of my source code files
min-text-lines value min-free           \ swapped between min-text and min-delete

: create-line-array ( n -- )            \ create line array, n lines
    min-free + dup !ln-array-size
    1+ cells 2* mallocate !ln-array     \ 1 extra for dummy line
    make-dummy-line ;

: create-buffer ( name -- bp )          \ make a named buffer, name = 0 => no name
    curbuf >r                           \ save curbuf
    _create-buffer to curbuf
    0 create-line-array
    curbuf r> to curbuf ;               \ restore curbuf

: resize-line-array ( n -- )            \ resize line array to fit n more lines
    dup #lines + ln-array-size <= if    \ already fits
        drop exit
    then
    min-free + ln-array-size + dup !ln-array-size 1+ cells 2* mallocate  ( ptr )
    ln-array over #lines 1+ cells 2* move
    ln-array mfree
    !ln-array ;

: _open-array                           \ open ln-array at dotln
    1 resize-line-array
    dotln nth-l  dup cell+ cell+  #lines 1+ dotln - cells 2*  move ;

: _close-array                          \ delete line after dotln from ln-array
    dotln 2+ nth-l
    dup cell- cell-
    #lines 1+ dotln - cells 2*  move ;

: find-buffer ( str$ - bp | 0 )         \ search for buffer named counted str$
    buffer-head dl-forward      ( str bp )
    begin
        dup buffer-head = if
            2drop false exit
        then
        2dup b>name @ swap $icmp
    while
        dl-forward
    repeat
    nip ;

: find-buf ( b/f -- bp | 0 )    \ find undisplayed buffer, backward from curbuf
    curbuf
    begin                       ( b/f buf )
        dup buffer-head <> if           \ skip head buffer
            dup b>wind @ 0= if          \ displayed?
                nip exit
            then
        then
        over execute                    \ previous or next buffer
    dup curbuf = until                  \ till full circle
    2drop 0 ;                           \ none found

: find-next-buf ( -- bp | 0 )    \ find undisplayed buffer, forward from curbuf
    ['] dl-forward find-buf ;

: find-prev-buf ( -- bp | 0 )   \ find undisplayed buffer, backward from curbuf
    ['] dl-backward find-buf ;

: swap-dot/mark                         \ swap dot and mark
    dotln dotofs markln markofs
    !dotofs !dotln !markofs !markln ;

\ address of current buffer flags
: b.flags ( -- addr ) curbuf b>flags ;

\ Set/Get buffer flags
: modified?
    bf-modified b.flags test-bits 0<> ;
: set-modified
    bf-modified b.flags set-bits ;
: reset-modified
    bf-modified b.flags reset-bits ;

: show-marked
    bf-show-marked b.flags set-bits ;

in-editor

: show-marked? ( -- flag )
    bf-show-marked b.flags test-bits 0<> ;

: auto-indent? ( -- flag )
    bf-auto-indent b.flags test-bits 0<> ;
: enable-auto-indent
    bf-auto-indent b.flags set-bits ;
: disable-auto-indent
    bf-auto-indent b.flags reset-bits ;
: toggle-auto-indent
    bf-auto-indent b.flags toggle-bits ;

: overwrite? ( -- flag )
    bf-overwrite b.flags test-bits 0<> ;
: toggle-overwrite
    bf-overwrite b.flags toggle-bits ;
: enable-overwrite
    bf-overwrite b.flags set-bits ;
: disable-overwrite
    bf-overwrite b.flags reset-bits ;

: word-wrap? ( -- flag )
    bf-wrap b.flags test-bits 0<> ;
: toggle-word-wrap
    bf-wrap b.flags toggle-bits ;
: enable-word-wrap
    bf-wrap b.flags set-bits ;
: disable-word-wrap
    bf-wrap b.flags reset-bits ;

: read-only? ( -- flag )
    bf-r/o b.flags test-bits 0<> ;
: toggle-read-only
    bf-r/o b.flags toggle-bits ;
: enable-read-only
    bf-r/o b.flags set-bits ;
: disable-read-only
    bf-r/o b.flags reset-bits ;
