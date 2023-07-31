\ EDIT  --  external edit functions                         11-01-99 20:59:57

in-editor

: insert-chars ( char n -- )            \ insert n chars
    flagdot _insert-chars ;

: insert-char ( char -- )
    1 insert-chars ;

: insert-string ( addr cnt -- )         \ insert string into line
    _insert-string flagdot ;

in-hidden

: indent-to-above                       \ indent dot line as per line above
    dotln 0= if  exit  then             \ ignore if on first line
    dotln 1- !dotln  0 !dotofs
    0 begin     ( i)
        dup dotlen <
        over dotlp + c@ iswhite? and
    while
        1+
    repeat
    dotlp swap  dotln 1+ !dotln  0 !dotofs
    insert-string ;

in-editor

: new-line                              \ do new line and advance cursor
    overwrite? dotln #lines <> and if   \ in overwrite mode
        c-bol c-down                    \  just go to beginning of next line
    else
        flagdot
        split-line c-right
        auto-indent? if
            indent-to-above
        then
        flageow
    then ;

: insert-new-line                       \ insert a new line
    split-line flageow ;

: overwrite-char ( char -- )            \ overwrite a char
    dot-#toeol if
        _overwrite-char
        dotofs 1+ !dotofs
        set-modified
        flagdot
    else
        insert-char
    then ;

: stuff-char                            \ put the next key code into text
    msg" Press key to stuff"
    key overwrite? if
        overwrite-char
    else
        insert-char
    then
    msg" " 0 to msg-active ;

in-hidden

: #to-next-tab-stop ( -- n )            \ # chars to next tab stop
      tabsize dispofs over mod - ;

: to-next-tab-stop
    dispofs tabsize + dup tabsize mod -
    get-dotofs dotlen min !dotofs ;

: insert-tab
    use-hard-tabs if
        tab-ch c@ insert-char
    else
        many-spaces #to-next-tab-stop insert-string
    then ;

in-editor


: tab                                   \ insert a tab
    overwrite?
    dotofs dotlen < and if
        to-next-tab-stop
    else
        insert-tab
    then ;

: back-tab                              \ move to previous tab stop
    dotofs if
        dispofs 1- dup tabsize mod - get-dotofs !dotofs
    then ;

: set-tabsize ( n -- )                  \ set tab size to n
    tabmax min
    dup 2 < if                          \ if n < 2
        drop exit                       \ just ignore
    then
    dup !tabsize to read-tabsize ;

' tabsize alias tabsize? ( -- n )       \ return tab size of current buf

: repeat-key
    msg" n = " linein
    line-esc if  exit  then
    ed-tib ed-#tib @ source!
    0 0 parse-word          ( 0 0 addr cnt )
    >number 2drop drop      ( u )
    msg" Press key or key command to repeat "
    get-key ?dup if
        -1 = if                         \ execute function bound to ekey
            swap 0 ?do  dup execute  loop drop
        else                            \ insert key not bound
            swap insert-chars
        then
        0 to msg-active
        flagwindow
    else
        drop msg" Unbound key" bell
    then
;

in-hidden

: del-chars ( cnt -- )                  \ delete chars
    dup dot-#toeol > if                 \ will it delete past end of line?
        flageow
    else
        flagdot
    then
    delchars ;

in-editor

: delete-chars ( cnt -- )               \ delete chars
    true to del-right?
    true to del-operation?
    del-chars ;

: delete-char
    1 delete-chars ;

in-hidden

: full-tab-to-left? ( -- flag )
    dotofs tabsize < if
        false
    else
        dotlp dotofs + tabsize - tabsize
        many-spaces over compare 0=
    then ;

: undel-ro
    msg" Can't undelete in read-only mode" ;

in-editor

: delete-left                           \ delete the previous char
    dotln 0= dotofs 0= and if  exit  then
    overwrite? dot-#toeol and if
        c-left
        bl overwrite-char
        dotofs 1- !dotofs
    else
        0 to del-right?
        true to del-operation?
        full-tab-to-left? if            \ delete one tab left
            dotofs 1- tabsize mod 1+
            dotofs over - !dotofs
        else
            c-left 1
        then
        del-chars
    then ;

: delete-word                           \ delete to beginning of next word
    true to del-operation?
    true to del-right?
    dot-#toeol 0= if                    \ at end of line
        1 delchars
        flageow
    else
        dotofs
        c-word-right
        dotofs over -
        swap !dotofs
        delchars
        flagdot
    then ;

: ro-mode
    msg" Not allowed in read only mode" ;

: word>upper                            \ convert word to upper case
    read-only? if msg" Read only" exit then
    dot-#toeol if
        dotofs c-word-right dotofs swap ?do
            dotlp i + dup c@ toupper swap c!
        loop
        flagdot set-modified
    else
        c-word-right
    then ;

: word>lower                            \ convert word to lower case
    read-only? if ro-mode exit then
    dot-#toeol if
        dotofs c-word-right dotofs swap ?do
            dotlp i + dup c@ tolower swap c!
        loop
        flagdot set-modified
    else
        c-word-right
    then ;

: delete-eol                            \ delete to end of line
    true to del-operation?
    true to del-right?
    dot-#toeol delchars
    flageow ;

: smart-delete-eol                      \ delete whole line if in first col
    true to del-operation?              \  delete LF if in last col
    true to del-right?
    dot-#toeol
    dotofs if
        dot-#toeol 0= if 1+ then        \ last col
    else
        1+                              \ first col
    then
    delchars flageow ;

: delete-line                           \ delete whole line
    c-bol smart-delete-eol ;

: undelete                              \ undelete last deleted stuff
    read-only? if  undel-ro exit  then
    show-marked? if msg" Mark set" exit then
    true to ud-operation?
    false to paste-operation?
    topln
    undelete-last
    !topln flageow ;

: undelete-prev                         \ undelete previous deleted stuff
    read-only? if  undel-ro exit  then
    show-marked? if msg" Mark set" exit then
    true to ud-operation?
    topln
    undel-udb/paste
    !topln flageow ;

: indent-line                           \ increase indent on line
    dotofs  0 !dotofs  insert-tab  !dotofs ;

: undent-line                           \ decrease indent on line
    dotofs          ( dotofs )
    0 !dotofs
    c-char tab-ch c@ = if  1  else  tabsize  then
    delete-chars
    dotlen min !dotofs ;

: block>upper                           \ upper case all words in block
    show-marked? 0= if
        word>upper exit
    then
    dot-first  dotln dotofs
    begin
        is-mark-first? 0=
    while
        word>upper
    repeat
    !dotofs !dotln restore-dot/mark ;

: block>lower                           \ lower case all words in block
    show-marked? 0= if
        word>lower exit
    then
    dot-first  dotln dotofs
    begin
        is-mark-first? 0=
    while
        word>lower
    repeat
    !dotofs !dotln restore-dot/mark ;

: indent-block                          \ increase indent on lines in block
    show-marked? 0= if
        indent-line  dotofs dotlen min !dotofs  exit
    then
    dot-first  dotln dotofs
    begin
        indent-line
    dotln dup 1+ !dotln markln = until
    dotlen min !dotofs !dotln  restore-dot/mark ;

: undent-block                          \ decrease indent on lines in block
    show-marked? 0= if
        undent-line  dotofs dotlen min !dotofs  exit
    then
    dot-first  dotln dotofs
    begin
        undent-line
    dotln dup 1+ !dotln markln = until
    dotlen min !dotofs !dotln  restore-dot/mark ;

in-hidden

: delete-buffer                         \ delete the current and display next
    curbuf 0= if exit then
    curbuf dl-unlink        ( nextbuf )
    b-destroy                           \ destroy current buffer
    buffer-head dup dl-forward = if
        drop                            \ no buffers left
    else
        to curbuf                       \ make next buffer current
        find-next-buf switch-buffer     \ find undisplayed buf and switch to it
    then ;

: do-extension ( fname -- )   \ execute function associated with file extension
    count /ext dup 0= if  2drop s" ."  then
    file-extensions search-wordlist 0= if
        s" .default" file-extensions search-wordlist 0= if
            exit
        then
    then
    execute
    read-tabsize !tabsize ;

: _read&switch-to-file ( fname -- )     \ read a file and switch to it
    dup openbuf 0= if   ( fname fid )
        swap do-extension               \ process extension first
        read-tabsize !tabsize
        readlines
        c-bof
    else
        drop do-extension
    then ;

defer check-backup                      \ forward reference

: read&switch-to-file ( fname -- )      \ read a file and switch to it
    _read&switch-to-file check-backup ;

: switch-to-file ( fname -- fname flag ) \ flag=true if successful
    dup find-buffer dup if  ( fname bp )
        switch-buffer true
    then ;

in-editor

: switch/read-file ( $fname -- )        \ switch to file or read one in
    count fname1 1+ expand-path >int-sep ( a u)
    swap 1- c!
    fname1 switch-to-file 0= if
        read&switch-to-file
    else
        drop
    then ;

in-hidden

: process-tib ( "fname ... " -- )   \ read files
    begin
        bl word dup c@
    while               ( $str )
        switch/read-file
    repeat
    drop ;

: _in-fnames
    ed-tib ed-#tib @ source! ;

: in-fnames                             \ input line of file names
    msg" File names? " linein _in-fnames ;

: in-fname                              \ input one file name
    msg" New file name? " linein _in-fnames ;

in-editor

: _get-files ( "fname ..." -- )     \ read files in source, first one is current buffer
    false to read-only
    process-tib ;

: get-files             \ prompt for file names, then read files, first one is current buffer
    in-fnames _get-files ;

: view-file ( $fname -- )               \ view one file given file name
    true to read-only
    dup c@ if
        switch/read-file
    else
        drop
    then ;

: view-files            \ input file names, read files, make last one current
    in-fnames
    true to read-only
    process-tib ;

in-hidden

: buffers-remaining? ( -- flag )
    buffer-head 0= if 0 exit then
    buffer-head dup dl-forward <> ;

: ?exit-editor
    buffers-remaining? 0= if            \ last buffer?
        restore-screen
        bye                             \ and exit if no more buffers
    then ;

in-editor

: save-buffer                           \ save current buffer
    bf-changed b.flags test-bits if     \ save only if needed
        curbuf writebuf
        bf-modified b.flags reset-bits
        delete-backup
    then ;

: save-all
    curbuf
    begin
        save-buffer
        curbuf dl-forward to curbuf
    dup curbuf = until
    to curbuf ;

: save-exit                             \ save file, remove buffer and exit
    save-buffer                         \ write out the buffer
    delete-buffer                       \ delete the buffer
    ?exit-editor ;

: save-exit-all
    begin save-exit again ;

: nosave-exit                           \ remove buffer; exit if no more buffers
    bf-changed b.flags test-bits if
        msg" Buffer changed, quit anyway? (Y/N) "
        0 to msg-active
        ed-key tolower [char] y <> if
            exit
        then
    then
    delete-backup
    delete-buffer
    ?exit-editor ;

in-hidden

: save-on-exit ( -- )
    buffers-remaining? if
        save-all
    then ;

in-editor

: buffer-rename ( $fname -- )           \ change curbuf name
    bname mfree
    dup c@ 1+ mallocate         ( fname memptr )
    dup !bname                  ( fname memptr )
    $move ;

: rename-buffer                         \ rename the current buffer
    in-fname  bl word
    dup c@ if           ( fname )
        delete-backup               \ this is a bit dangerous, could lose backup
        buffer-rename                   \ should copy first
        _backup-cur
    else
        drop
    then
;

in-hidden

: backup-query-msg
    status-colour video-colour !        \ status line colour
    status-line# video-row !  video-col off
    s" Backup for " video-type
    bname count video-type
    s"  exists. Edit the File or the Backup (F/B)? " video-type
    video-col @ status-line# at-xy
    windcols blank>coln ;

: use-backup
    bname fname2 $move                  \ save current buffer name
    delete-buffer                       \ delete the current buffer
    fname1 _read&switch-to-file         \ read the backup
    fname2 buffer-rename                \ and rename it
    set-modified ;

: _check-backup                 \ is there a backup file to delete or rename?
    backup-fname
    fname1 count r/o open-file if   ( fid )
        drop
    else
        close-file throw
        begin
            backup-query-msg
            ed-key tolower dup [char] b = if
                drop use-backup exit
            then
            [char] f = if
                delete-backup exit
            then
        again
    then ;
' _check-backup is check-backup
