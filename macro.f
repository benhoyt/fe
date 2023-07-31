\ MACRO  --  keystroke macro definitions                    06-01-99 18:07:43

\ @@@ BUG: when doing delete and undelete inside a macro the flags
\  ud-operation? del-operation? paste-operation? are not set properly
\  must set them in cursor motion routines for macros to work properly

in-hidden

\ These macro routines do not handle exit to the forth command line, don't!!
\  Bound keys have the functions they are bound to compiled
\  Other keys are compiled as literals
\  Nor do they handle line input properly; this is especially needed for
\   search and search and replace

2variable key&xt                        \ save key and xt here

: end-macro-def
    false to defining?
    postpone flagwindow                 \ macro should always redisplay window
    key&xt 2@                           \ get function and key
    postpone ;                          \ compile exit
    edkeys to &chain                    \ add this bound key to edkeys
    bind: drop previous \ compile the bound function, drop key-table vocabulary
    1 , ,                               \ compile one key code
    msg" Macro defined" ;

in-editor

: define-macro                          \ define a macro for some key
    defining? if
        end-macro-def
    else
        msg" Press key to bind to macro definition: "
        ed-ekey     ( ekey )            \ key to bind
        msg" Press keys in definition; end with define macro key"
        true to defining?
        :noname                         \ function to bind
        postpone [              \ turn off compiling in case of exit to forth
        key&xt 2!                       \ save function and key
    then ;

in-hidden

\ These two compiling functions are called in edit-loop in main.f
: _macro-func-compile ( func -- )       \ compile a function
    defining? if
        dup ['] define-macro <> if
            postpone pre-cmd  compile,
            postpone post-cmd exit
        then
    then
    drop ;
' _macro-func-compile is macro-func-compile

: _macro-key-compile ( key -- )         \ compile a key as literal
    defining? if
        postpone literal postpone insert-char exit
    then
    drop ;
' _macro-key-compile is macro-key-compile
