\ LINEIN  --  line input routines                           11-01-99 21:00:09

in-hidden

60 value max-inline
variable ed-#tib
create ed-tib  max-inline allot

in-editor

variable lineinkeys

>chain: mark-chain ( -- )               \ store current keychain state
  lineinkeys @ , ;
>chain: prune-chain ( addr -- addr' )   \ restore keychain state
  @+ lineinkeys ! ;

in-hidden

: _linein ( flag -- )                   \ edit a line in ed-tib
    0 also-keys lineinkeys also-keys    \ use only lineinkeys for line input
    status-colour set-colour            \ status line attribute
    ed-tib max-inline rot if
        ed-#tib @ l-edit
    else
        l-accept
    then
    ed-#tib !
    prev-keys prev-keys                 \ restore curkeys
    0 to msg-active ;

in-editor

: +linein                               \ edit a line in ed-tib
    true _linein ;

: linein                                \ input a line into ed-tib
    false _linein ;
