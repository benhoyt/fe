\ BLOCK  --  marked block routines                          10-03-99 22:27:47

in-editor

: set-mark                              \ set mark at current cursor location
    dotln !markln
    dotofs !markofs
    show-marked                         \ enable marked block display
    flagwindow ;

: toggle-mark                           \ toggle marked block display
    bf-show-marked b.flags toggle-bits
    flagwindow ;

in-hidden

3 value max-#pbs                        \ maximum # of paste buffers
0 value #pbs                            \ current # in paste buff chain
0 value last-pb                         \ last past buffer undeleted from
true value pb-closed?                   \ to save udb-closed? and set it to true
0 value mark-first?                     \ is mark first?

: init-pbs
    0 to #pbs ;

: swap-udb/paste                        \ swap udb & past vars
    udb-head paste-head to udb-head to paste-head
    max-#udbs max-#pbs to max-#udbs to max-#pbs
    #udbs #pbs to #udbs to #pbs
    last-udb last-pb to last-udb to last-pb
    udb-closed? pb-closed? to udb-closed? to pb-closed?
    doing-paste? 0= to doing-paste? ;

: is-mark-first? ( -- flag )
    markln dotln <
    markln dotln = markofs dotofs <= and
    or ;

: dot-first                             \ force dot first
    is-mark-first? dup to mark-first? if \ need to swap?
        swap-dot/mark
    then ;

: restore-dot/mark
    mark-first? if
        swap-dot/mark
    then ;

: _cut                                  \ marked text to paste buffer
    true to pb-closed?                  \ always closed
    swap-udb/paste
    dot-first                           \ force dot before mark
    true to del-right?
    min-delete-lines markln dotln - 2+ to min-delete-lines
    dotofs negate dotln                 \ don't count initial offset
    begin           ( cnt ln )          \ count how many chars to delete
        dup markln <>
    while
        dup nth-len 1+ under+           \ including LF
        1+
    repeat
    drop
    markofs + _delchars                 \ count final offset
    to min-delete-lines
    dotln !markln dotofs !markofs
    swap-udb/paste ;

: _paste                                \ undelete from paste buffer
    swap-udb/paste
    undelete-last
    swap-udb/paste ;

in-editor

: cut                                   \ cut marked block or line
    read-only? if msg" Can't cut in read-only mode" exit then
    show-marked? 0= if msg" Nothing marked" exit then
    dotln topln -
    _cut toggle-mark
    ?adjust-top-line flagwindow ;

: paste
    show-marked? if msg" Mark set" exit then
    read-only? if msg" Can't paste in read-only mode" exit then
    true to ud-operation?
    true to paste-operation?
    dotln topln - _paste ?adjust-top-line flagwindow ;

: duplicate
    show-marked? 0= if msg" Nothing marked" exit then
    read-only? dup if  toggle-read-only  then  ( rof )
    modified?                                   ( rof modf )
    dotln topln -               ( rof modf dlf ln )
    _cut
    dup ?adjust-top-line        ( rof modf dlf )
    _paste
    restore-dot/mark
    ?adjust-top-line            ( rof modf dlf )
    0= if reset-modified then   ( rof )
    if toggle-read-only then
    toggle-mark flagwindow ;

in-hidden

: undel-udb/paste                       \ undelete previous deletion
    paste-operation? 0= if              \ is this a block operation?
        undel-prev                  \ yes, so undelete previously deleted block
    else
        swap-udb/paste                  \ no, so swap to undelete pointers
        undel-prev                      \ and undelete previously deleted buffer
        swap-udb/paste
    then
;

: _insert-file ( addr u -- )            \ insert file fname
    dotln topln - >r           ( addr u R: n )
    split-line c-right
    readinfile
    show-marked                         \ mark now before dot
    false to save-deleted?
    last-char c@ lf-ch <> if
        c-left 1 delchars
    then
    swap-dot/mark
    c-left 1 delchars
    swap-dot/mark
    true to save-deleted?
    set-modified
    r> ?adjust-top-line flagwindow ;

in-editor

: insert-file                           \ insert file
    read-only? if  msg" Can't read in file in read-only mode" exit  then
    msg" File name? " linein
    line-esc if exit then
    ed-tib ed-#tib @ ( 2dup use/ ) _insert-file ;

in-hidden

: _write-block ( addr u -- )            \ write marked lines to file; dot first
    r/w create-file throw >r ( R: fid ) \ create file
    dotln markln = if
        dotptr markofs dotofs - r@ write-file throw
    else
        dot-tail r@ write-line throw
        r@ markln dotln 1+ writelines
        markln nth-lp markofs r@ write-file throw
    then
    r> close-file throw
    restore-dot/mark
    toggle-mark ;

in-editor

: write-block                           \ write marked lines to file
    show-marked? 0= if msg" No mark set" exit then
    dot-first
    msg" File name? " linein
    line-esc if exit then
    ed-tib ed-#tib @ _write-block ;

in-hidden

variable st-buf-line                    \ start line in buffer
variable end-buf-line                   \ end line in buffer
variable save-base                      \ initially set by edsetup

: in-buf-line ( -- flag )               \ input from buffer
    st-buf-line @ end-buf-line @ < if
        st-buf-line @ nth-str
        tuck line-buf swap move
        line-buf swap source!           \ source is current line
        1 st-buf-line +!
        true
    else false source >in ! drop then ; \ at end of buffer


0 value blk-restore-terminal

: blk-include ( end-ln st-ln -- )
    ['] terminal is? >r                 \ save current terminal function
    r@ to blk-restore-terminal          \ save old terminal in case user invokes SAVE during blk-include
    save-base @  base !
    ['] in-buf-line is terminal
    st-buf-line ! end-buf-line !
    editing? if
        0 status-line# at-xy eeol
        init-forth-screen
    then
    ['] includer catch ?dup if
        ." Error caught on line " st-buf-line @ .
        ."  Interpreting " parsed 2@ type ."  <-- "
        dup throw-msg if
            type drop                   \ display message for this throw code
        else  2drop  ." Unknown exception # " .d  then
        source nip >in !
        end-buf-line off
        st-buf-line @ goto-line#
        init-interp                     \ what quit would do after normal error; turns state off
    then
    editing? if
        cr ." Press a key to continue ..." key drop
        init-editor-screen
    then
    flagwindow
    base @  save-base !  decimal
    r> is terminal
    0 to blk-restore-terminal ;         \ restore terminal function

>chain: init-chain                      \ workaround in case user invokes SAVE during blk-include
    ['] terminal is?
    ['] in-buf-line = if
        blk-restore-terminal is terminal
    then ;

in-editor

\ include marked block; or dot line if nothing marked
: include-block
    show-marked? if
        dot-first
        markln markofs 0> if 1+ then
        dotln
        restore-dot/mark
        toggle-mark
    else
        dotln 1+  dotln
    then  blk-include ;

\ include current buffer
: include-buffer
    #lines 0 blk-include ;
