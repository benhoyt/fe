\ WIND  --  Window structure and routines                   11-01-99 21:00:28

\ only need one window, keep histories in buffers, display them if needed
\ may want popup selection windows for histories and files

\ All text entry is done in a window into an edit buffer
\  including file history
\  open file selection window

\ Open file selection window uses a temporary buffer, deleted after use


in-hidden

\ Window structure: doubly linked list
dl-links-size
cell field w>buf                        \ buffer displayed in this window
cell field w>row-flags                  \ ptr to array of display flags
byte field w>strow                      \ start row of window
byte field w>stcol                      \ start col of window
byte field w>#rows                      \ #rows in window
byte field w>#cols                      \ #cols in window
constant w-size                         \ window structure size

0 value window-head                     \ head of window list
0 value curwind                         \ currently active window

\ fetch window values
: windbuf curwind w>buf @ ;
: windrow-flags curwind w>row-flags @ ;
: windstrow curwind w>strow c@ ;
: windstcol curwind w>stcol c@ ;
: windcols curwind w>#cols c@ ;
: windrows curwind w>#rows c@ ;

' windrows alias status-line#

: windrow ( -- n )                      \ # of dot row in window
    dotln topln -
    dup windrows u< 0= if
        drop 0
    then ;

\ flag rows for display
: th-row-flag-on ( n -- )
    windrow-flags + true swap c! ;
: th-row-flag-off ( n -- )
    windrow-flags + false swap c! ;
: th-row-flag? ( n -- flag )
    windrow-flags + c@ ;
: flagwindow                            \ flag all rows in window
    windrows 0 ?do  i th-row-flag-on  loop ;
: flagall flagwindow ;                  \ dummy for now; flag all rows in all windows
: flageow                               \ flag all rows from dot to eow
    windrows windrow ?do  i th-row-flag-on  loop ;
: flagdot                               \ flag dot row
    windrow th-row-flag-on ;
: flags-off                             \ all row flags off
    windrows 0 ?do  i th-row-flag-off  loop ;

: w-destroy ( wp -- )                   \ free memory allocated for window
    dup w>row-flags @ mfree
    mfree ;

: w-init ( wp -- )                      \ init a window struct
    dup w>buf off
    0 over w>strow c!
    0 over w>stcol c!
    screen-rows 1- over w>#rows c!      \ allow for status line
    screen-cols over w>#cols c!
    screen-rows 1- mallocate over w>row-flags !
    w>row-flags @ screen-rows 1- erase ;

: w-create ( -- wp )                    \ create a new window struct
    w-size mallocate                    \ size of window struct
    dup dl-self
    dup w-init ;

\ do once at program start-up
: init-windows
    0 to curwind
    w-create to window-head ;           \ dummy head window

: open-edit-window ( bp -- wp )       \ open a new edit window, make it curwind
    w-create        ( bp wp )
    dup window-head dl-link             \ link wp at end of window list
    2dup w>buf !                        \ this window points to the buffer
    2dup swap b>wind !
    dup to curwind                      \ set curwind and curbuf
    swap to curbuf ;

: switch-buffer ( bp -- )               \ switch current window to buffer bp
    ?dup 0= if exit then
    curbuf b>wind off                   \ curbuf no longer displayed
    dup to curbuf
    curwind w>buf !                     \ make curwind point to buffer
    curwind curbuf b>wind !             \ new curbuf points to curwind
    flagwindow ;

\ Forward references
defer nxtwnd
defer prvwnd

in-editor

: prev-buffer                   \ switch to previous undisplayed buffer in ring
    find-prev-buf ?dup if
        switch-buffer
    else
        nxtwnd                      \ if no more buffers, switch to next window
    then
;

: next-buffer                       \ switch to next undisplayed buffer in ring
    find-next-buf
    ?dup if
        switch-buffer
    else
        prvwnd
    then
;

0 [if]
: switch_window ( wp -- )               \ switch to another window
    windofs dup to curwind
    curwind w>buf @ to curbuf           \ make this buffer current
    0 to line#
    flagall ;

: next_window
    curwind dl-forward dup window_head = if
        dl-forward
    then
    dup curwind <> if
        switch_window
    then
    drop ;
' next_window is nxtwnd

: prev_window
    curwind dl-forward dup window_head = if
        dl-forward
    then
    dup curwind <> if
        switch_window
    then
    drop ;
' prev_window is prvwnd
[then]
