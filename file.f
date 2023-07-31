\ FILE  --  Editor file handling routines                   11-01-99 21:00:05

in-hidden

0 value read-only                       \ signal read only for read-only files

: openbuf ( fname -- file flag )    \ open file, create new buffer, make curbuf
    dup count r/o open-file     ( fname file flag )
    rot create-buffer           ( file flag bp )
    dup buffer-head dl-link             \ link new buffer
    curbuf if
        switch-buffer
        read-only if
            toggle-read-only            \ force to read only
        then
    else
        open-edit-window drop
    then
;

0 value line-buf                        \ buffers long enough for one full line
0 value line1-buf

: allocate-line-bufs
    l-limit 2+ mallocate to line1-buf
    l-limit 2+ mallocate to line-buf ;

\ Copy src to dest expaning tabs
: expand-tabs ( src len dest -- dest len' )
    0 2swap           ( dest 0 src cnt )
    bounds ?do                  ( dest cnt' )
        i c@ tab-ch c@ <> if    ( dest cnt' )
            2dup + i c@ swap c!  1+
        else
            read-tabsize 2dup mod - 0 ?do
                2dup + bl swap c!  1+
            loop
        then
    loop ;

\ Expand tabs if present
: _expand-tabs ( buf cnt -- buf' cnt' ) \ expand tabs if any present
    2dup tab-ch c@ scan nip if          \ any tabs to expand?
        line1-buf expand-tabs
    then ;

create last-char -1 ,

\ Use this after reading whole file to check for line terminator at end of
\   last line in file
: get-last-char ( file -- )
    >r
    r@ file-size throw drop
    1- 0 max 0 r@ reposition-file throw \ back up one char
    last-char 1 r> read-file throw      \ read last char
    0= if last-char on then ;           \ nothing read so reset last-char

: readlines ( file -- )                 \ read lines from file
    dotln !markln dotofs !markofs  \ mark at start, dot at end of stuff read in
    >r
    begin                           ( R: file )
        line-buf l-limit r@
        read-line throw             ( cnt flag R: file )
    while                           ( len  R: file )
        line-buf swap               ( line-buf len R: file)
        detab-on-read if
            _expand-tabs
        then
        dup lmalloc 2dup 2>r        ( line1-buf len ptr R: file len ptr )
        swap move                   ( R: file len ptr )
        r> r> _insert-as-dot-line   ( R: file )
        dotln 1+ !dotln
    repeat                          ( cnt R: file)
    r@ get-last-char                    \ save last char of file
    drop r> close-file drop ;

: readinfile ( addr u -- )              \ read in file named addr:u
    dup 0= if
        2drop exit                      \ no file name
    then
    r/o open-file throw     ( fileid )
    readlines ;

: trailing ( addr cnt -- addr cnt' )    \ conditionally trim white space
    trim-line? if
        -trailing
    then ;

: full-tab? ( addr len -- flag )        \ is there a full tab at addr
    tabsize < if
        drop false
    else
        tabsize bl skip nip 0=
    then ;

: replace-tabs ( src len -- addr u )    \ replace tabsize spaces with a tab
    line-buf -rot               ( ptr src len )
    begin
        dup
    while                       ( ptr src len )
        2dup full-tab? if
            2>r tab-ch c@ over c! 1+
            2r> tabsize /string
        else                    ( ptr src len )
            dup tabsize min >r  ( ptr src len R: #mv )
            over 3 pick r@ move
            r@ /string
            rot r> + -rot       ( ptr src len )
        then
    repeat
    2drop line-buf tuck - ;

: writelines ( file eln sln -- )        \ write lines to file
    ?do                                 ( file )
        dup i nth-str trailing ( file file addr cnt )
        save-with-tabs if
            replace-tabs
        then
        rot write-line throw
    loop
    drop ;

\ buffers for path & file name handling
0 value fname1                          \ ptr to file name and path
0 value fname2                          \ ptr to second file name and path
0 value bakpath                         \ ptr to back up path

: init-filename-bufs
    256 mallocate to fname1
    256 mallocate to fname2
    256 mallocate to bakpath ;

create tmpext ," .X7~"                  \ assume fname.X7~ is a unique file name
create bakdir ," backdir"               \ create a new dir for backup files
create bakext ," .bak"                  \ an extension for backup files

: writebuf ( bp -- )                    \ write contents of buffer to file
    curbuf >r to curbuf
    #lines 0= if
        bname count delete-file drop    \ buffer empty so erase the file
    else
        bname count fname1 place
        fname1 count /ext nip ?dup if
            negate fname1 c+!           \ reverse over .ext
        then
        tmpext count fname1 append      \ fname.X7~ at fname1
[ Linux ] [if]
\ get file permission bits of bname and create fname1 with them
        create-permissions >r
        bname count file-status 0= if
            st_mode + w@ &777 and
            to create-permissions
        else drop then
        fname1 count r/w create-file throw ( file R: bp perms)
        r> to create-permissions
[else]
        fname1 count r/w create-file throw ( file R: bp)
[then]
        dup #lines 0 writelines
        close-file throw
        bname count delete-file drop \ discard error since file might not exist
        fname1 count bname count rename-file throw
    then
    r> to curbuf ;

create _sep-ch 1 c, int-sep-ch c,

allow-dir-creates [if]
\ back up path d:\path\backdir at bakpath
\ back up file name d:\path\backdir\fname.ext at fname1
\   and temporary file name d:\path\backdir\fname.X7~ at fname2
: backup-fname
    bname count /path bakpath place
    bakdir count bakpath append         \ d:\path\bakdir at bakpath
    bakpath count fname1 place
    _sep-ch count fname1 append
    bname count /file.ext fname1 append \ d:\path\bakdir\fname.ext at fname1
    fname1 count fname2 place
    fname2 count /ext nip ?dup if
        negate fname2 c+!
    then
    tmpext count fname2 append ;        \ d:\path\bakdir\fname.$X7 at fname2
[else]
\ assume implementations without create-dir will handle long file names
: backup-fname
    bname count fname1 place
    fname1 count fname2 place
    bakext count fname1 append          \ fname.ext.bak at fname1
    tmpext count fname2 append ;        \ fname.ext.X7~ at fname2
[then] \ allow-dir-creates

: write-no-trim ( file -- )
    trim-line? >r 0 to trim-line?       \ don't trim
    dup
    #lines 0 writelines                 \ write the whole buffer
    r> to trim-line?
    close-file throw ;

: _backup-cur                           \ backup current buffer
    backup-fname                        \ create the backup file and dir names
[ allow-dir-creates ] [if]
    bakpath count create-dir drop
[then]
    fname2 count r/w create-file throw  \ create 2nd backup file
    write-no-trim
    fname1 count delete-file drop       \ delete 1st backup - might not exist
    fname2 count fname1 count rename-file throw \ now rename 2nd backup
    bf-backup b.flags reset-bits ;      \ now fully backed up

: backup
    curbuf dup
    begin
        dl-forward                      \ start with next buffer
        dup b>flags c@ bf-backup and if \ check backup flag, need to backup?
            dup to curbuf               \ yes, switch to this buffer and backup
            _backup-cur
        then
    2dup = until                        \ until we get around to start point
    drop to curbuf ;

: delete-backup
    backup-fname                        \ create the backup file & dir names
    fname1 count delete-file drop
    fname2 count delete-file drop
[ allow-dir-creates ] [if]
    bakpath count delete-dir drop       \ this will work only if dir is empty
[then] \ allow-dir-creates
;

: get-secs ( -- u )                     \ current time in seconds
    time&date drop 2drop                \ throw away date
    3600 *                              \ hours * 3600
    swap 60 * + + ;                     \ minutes * 60 + seconds

\ Timed backup parameters - time in seconds
0 value last-backup                     \ time of last auto backup or save
180 value backup-interval               \ default = 3 minutes

in-editor

: set-backup-interval ( n -- )          \ set backup interval in secs
    to backup-interval ;

: backup-interval? ( -- n )             \ get backup interval in secs
    backup-interval ;

in-hidden

: bk-ekey ( -- key )                    \ check for timed backup while waiting
    last-backup 0= if                   \   for next key
        get-secs to last-backup         \ initialize last-backup
    then
    get-secs dup last-backup -          \ time since last save
    backup-interval > if                \ backup overdue?
        to last-backup                  \ reset save time
        backup                          \ do it!
    else
        drop
    then
    ekey ;                              \ return the key

' bk-ekey is ed-ekey
