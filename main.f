\ MAIN  --  Main loop                                       11-01-99 21:00:16

in-editor

: exit-editor                           \ exit to forth
    1 throw ;

in-hidden

: pre-cmd
    false to up/down                    \ reset cursor up or down flag
    false to del-operation?             \ reset delete operation flag
    false to ud-operation?              \ reset undelete operation flag
;

: post-cmd
    up/down 0= if                       \ if not up or down
        -1 to prevcol                   \ reset previous col
    then
    del-operation? 0= if                \ if not delete
        true to udb-closed?             \ close the undelete buffer
    then
    ud-operation? 0= if
        false to last-udb           \ no last udb
        false to last-pb            \ no last paste buf
        false to paste-operation?   \ back to udb undeletes
    then
;

defer auto-word-wrap  ' noop is auto-word-wrap
defer macro-func-compile  ' drop is macro-func-compile
defer macro-key-compile  ' drop is macro-key-compile
0 value prev-char

: edsetup                               \ setup for edit loop
    draw-style if
        enable-draw
    else
        disable-draw
    then
    base @ save-base !  decimal
    flagall ;                           \ flag initial screen display

: edunsetup
    save-base @ base !
[ Windows ] [if]
    init-forth-screen                   \ position cursor and erase status line
[then]
[ Linux ] [if]
    restore-screen                      \ position cursor and erase status line
[then]
;

: edit-loop
    begin                               \ main loop
        display                         \ display the screen
        pre-cmd get-key     ( 0 | key 1 | func -1 )
        msg-active if
            msg" "  0 to msg-active     \ clear the message line
        then
        ?dup if                     ( key 1 | func -1 )
            -1 = if                 ( func )
                dup >r catch r>     ( 0 func | n func )
                macro-func-compile  ( 0 | n )
                ?dup if  ( n )
                    dup 1 = if  ( 1 )   \ 1 thrown => exit to forth
                        drop exit
                    else
                        edunsetup
                        ." Exception in edit loop: " \ signal the exception
                        throw
                    then
                then
            else            ( key )
                dup macro-key-compile   ( key )
                dup to prev-char
                overwrite? if
                    overwrite-char
                else
                    insert-char         \ insert the char
                then
                auto-word-wrap
            then
        else
            msg" Unbound key" bell
        then
        post-cmd
    again ;

: edit-args                             \ process command line args
    command-line source!
    begin
        /source nip
    while
        filename
        2dup s" -e" compare if
            dup if
                fname2 place
                fname2 switch/read-file
            else 2drop  then
        else
            2drop -1 parse evaluate quit \ if -e on command line, exit automatically afterward
        then
    repeat ;

: _edit ( -- )                          \ read file and enter editor
    edsetup
    begin
        ['] edit-loop catch
    dup -28 <> until                    \ in case Ctrl-C causes user throw
    edunsetup                           \   as GForth does
    ?dup if throw then ;

: editor-init                           \ do once off initialisations
    init-buffers
    ['] save-on-exit  ['] exit-chain  >chain
    init-windows
    0 to last-backup
    init-udbs init-pbs
    init-filename-bufs
    allocate-vid-bufs
    allocate-line-bufs
    get-secs to last-backup ;

in-editor

here ," fe.cfg" value config-file

in-hidden

0 value config-path

: try-config-path ( a u -- flag )       \ try opening string at config-path
  2dup r/o open-file if
    drop 2drop false exit
  then  close-file drop
  here -rot s, to config-path  true ;

: find-config-file ( -- )               \ return name or zero in config-path if not found
  0 to config-path
\ look in current dir first
  config-file count try-config-path ?exit
\ then in path where prog is found
  prog-name /path  dup config-file c@ +  s-buf-mem >r  r@ place
  config-file count r@ append
  r> count  try-config-path ?exit
[ allow-getenv ] [if]
\ then in editor environment variable FE_CFG
  s" FE_CFG" getenv dup if  try-config-path ?exit  else 2drop then
[then]
;

\ include config file; first try current directory;
\  then prog.exe path; then full path in FE_CFG
: do-config ( -- )
  find-config-file
  config-path if  config-path count included  then ;

0 value init-finished

: (edit)                                    \ re-enter editor
    true to editing?
    init-editor-screen
    ['] _edit catch ?dup if
        c-bof init-forth-screen
        ." Exception in editor: " throw
    then
    false to editing? init-forth-screen ;

in-forth

: edit ( ["name ..."] -- )
    init-finished 0= if
        editor-init
        do-config
        only forth also editor
        true to init-finished
    then
    >in @ parse-word nip swap >in ! if  \ any file names?
        _get-files
    then
    curbuf if
        (edit)
    else
        c" Unnamed" switch/read-file (edit)
    then ;
' edit is to-editor
throw-msg

in-hidden

\ Boot up sequence; hook this into your FORTH boot up sequence and then
\   re-save your forth system. Now you should have an editor that boots
\   from the command line.
: boot-editor
    editor-init
    do-config                           \ ignore absent configuration file
    only forth definitions also editor
    true to init-finished
    edit-args                           \ read file specified on command line
    curbuf if
        buffer-head dl-forward switch-buffer \ switch to first file
        (edit)
    then
    command-line nip 0= if              \ were any files read?
        ." Usage:  FE filename [...]" cr
    then
    interact on
    prompts @ if hello then  quit ;     \ don't process command line again
