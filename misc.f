\ MISC  --  Miscellaneous functions                         11-01-99 21:00:21

in-hidden

: 2digits
    0 <# # # #> type ;

: 4digits
    0 <# # # # # #> type ;

in-editor

: .date
    time&date >r >r
    2digits ." -" r> 2digits ." -" r> 2digits
    drop 2drop ;

: .rdate
    time&date 4digits ." -"
    2digits ." -" 2digits
    drop 2drop ;

: .time
    time&date drop 2drop
    2digits ." :" 2digits ." :" 2digits ;

: date&time
    ['] type is? ['] insert-string is type
    .date space .time space
    is type ;

: eob? ( -- t/f )                       \ at end of buffer?
    dotln #lines = ;

: cur-line# ( -- n )                    \ get current line #
    dotline# ;

: #cols ( -- n )                        \ number of cols in dot line
    dotofs  dotlen !dotofs  dispofs  swap !dotofs ;

: buffer-name ( -- addr cnt )           \ buffer name string
    bname count ;

: file-header
    c-bol delete-eol
    ['] type is? ['] insert-string is type
    ." \ " buffer-name /file.ext type
    2 spaces .rdate ."   --  "
    is type ;

allow-shell [if]

: to-shell                              \ shell to DOS from editor
    init-forth-screen
    s" " system
    init-editor-screen
    flagall ;

in-hidden

create src-pipe ," srcpipe.iii"
create dest-pipe ," destpipe.ooo"

in-editor

: _filter-block ( addr u -- )           \ filter hilighted block
    dot-first
    src-pipe count _write-block
    s" <" fname1 place src-pipe count fname1 append
    s"  " fname1 append ( addr u ) fname1 append
    s"  >" fname1 append dest-pipe count fname1 append
    fname1 count system
    _cut
    200 ms
    dest-pipe count _insert-file        \ mark now before dot
    src-pipe count delete-file drop
    dest-pipe count delete-file drop ;

: filter ( -- )
    show-marked? if
        msg" Pass marked block through what filter? "
    else
        msg" Pass buffer through what filter? "
    then
    linein  line-esc if exit then
    ed-tib ed-#tib @
    dup if
        show-marked? if
            _filter-block
        else
            toggle-mark
            0 !dotln 0 !dotofs
            #lines !markln 0 !markofs
            _filter-block
            toggle-mark
        then
    else 2drop then ;

: do-command ( addr u -- )
    s" comspec" getenv  path-max min  fname1 place
    s"  /C " fname1 append
    fname1 append
    s"  > " fname1 append
    dest-pipe count fname1 append
    fname1 count system
    100 ms
    dest-pipe count _insert-file        \ mark now before dot
    dest-pipe count delete-file drop ;

: command ( -- )                        \ insert results of command in buffer
    msg" Insert results of what command? "
    linein  line-esc if exit then
    ed-tib ed-#tib @
    dup if do-command else 2drop then ;


: script ( -- )
\ execute the contents of the current
\  buffer as a shell script
;

[then] \ allow-shell

