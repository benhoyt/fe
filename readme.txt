               Forth Editor by Bruce Hoyt


The forth editor FE is freeware. If you use it, I only ask that you
acknowledge the source for any part of it that you may use in your own
code.


INSTALLATION
------------

Unzip the source files in a directory of your choice. Set an environment
variable FE_CFG to the path and filename of the FE configuration file
FE.CFG. For example in MS-DOS:

    set FE_CFG=c:\home\fe\fe.cfg

Then edit the configuration file FE.CFG and put it in the directory you
specified in FE_CFG. Note that FE will look first in the current directory
for FE.CFG before checking FE_CFG. This allows project specific
configurations to be defined.

    include FE.F

Note: There are three non-standard words used by FE:
    INCLUDE  FORTH  VOCABULARY
Most forth systems have these.


OPERATION
---------

FE is intended to be added to your forth system so that it cold boots
automatically. If you don't have a cold boot DEFERed word then comment out
the following line in your make file.
    ' boot-editor is ...

You can start up the editor from the forth command line as follows:
    edit filename1 [filenames ...]
All the files listed on the command line will be read into edit buffers in
memory.

The ESC key will exit back to the forth command line. Another edit command
will return you to the editor screen.


USAGE    (for bootable FE)
-----

FE [file1 ...]

The arguments, file1 ..., will be read into memory edit buffers for
editing.

Consult FE.KEY to see or change the key bindings.

Consult FUNCS.TXT for an explanation of the edit functions. These can all
be bound to keys or used in a FORTH word.

Consult FE.CFG to see an example of configuration options.


BACKGROUND
----------

FE is based on heavily modified code which I originally stole from the
micro-emacs editor. However, don't think that you will find much that looks
like C code or micro-emacs here. Only a few ideas remain. The key binding
is like WordStar rather than micro-emacs.

Originally FE was written in my own personal version of Forth. Modifying
FE to make it more ANS Forth-like has improved it.

It is still not fully ANS Forth compatible, however, since I am not willing
to give up some features which ANS Forth does not address. Namely, creating
and deleting sub-directories, finding files within a directory, processing
the OS command line, performing OS shell commands and most importantly fast
screen writing with colour. In addition system dependent control keys and
function keys are used.

If you check the file (FED.F) you will find options which allow you
selectively to enable or disable the above features. But I wouldn't want to
use the editor with all of them disabled! Too slow on screen unless your
forth has a very fast TYPE. And too limited. The main make file is BUILD.F
which is included by FED.F

To discover the editing functions available and a brief description of what
they do look at FUNC.TXT. This coupled with the key bindings file FE.KEY
and the configuration file FE.CFG show the substance of the user interface
of the editor. (Note: you should put FE.CFG in either the directory
indicated by the environment variable FE_CFG or in a directory in your PATH
together with FE.EXE


INTERNAL Description
--------------------

FE reads all files to be edited (i.e. those listed on the command line)
into allocated memory. The amount of (virtual) memory you have available is
the limitation on the total file size. The variables for each file are
stored in a structure I call a buffer (a name used in micro-emacs). The
buffers are kept in a doubly linked list and any buffer can be displayed by
circling forward or backward through the buffer ring.

Internally the buffers hold information about the dot line (i.e. the cursor
line, a term also used by micro-emacs) the mark line (the other end of a
selected block of text), the offset of the dot and the mark in their
respective lines, the tabsize for this buffer, the number of lines in the
file, and an array of pointers and lengths of all the lines. Memory is
allocated dynamically for each buffer structure and for each line of text
in the buffer. Although micro-emacs keeps its lines in a linked list, I
found this cumbersome in several ways. I changed to the array of pointers
and lengths mentioned above and was able to simplify and shrink the code
quite a bit. This array has to be resized from time to time as the number
of lines increases. I do so in increments of 1024.

As a line is edited, I resize it as necessary in increments of 8 bytes.
This avoids having to keep an allocated size as well as the current size
for each line.

The display routines use an array of line flags which indicate whether the
line needs to be re-displayed. Re-display occurs each time through the main
edit loop (i.e. every key press). However only the modified lines are
redisplayed. Thus the slowest actions are deletion/insertion of a line and
scrolling the screen. Different colours can be used for the cursor line,
normal text lines, selected text (marked lines) and the status line.

The status line at the bottom of the screen shows the current line number,
the total number of lines in the buffer, the current column number, a
series of flags indicating indent mode, overwrite mode, read-only mode,
word-wrap mode, line drawing mode, and tabsize, followed by the hex value
of the current character and the file name (with full path if this option
is compiled in). An asterix preceding the file name signals that the buffer
has been modified.

A configuration file (FE.CFG) is read at startup (from the local directory
or, if not found, from the directory in which the editor was located). It
can be used to set the auto-backup interval, file extension options,
tabsize, screen colours, include search path, etc.

There is no undo feature (since I don't use one) but there is both undelete
and block cut and paste. The last three deletions are kept and these may be
undeleted. Furthermore contiguous deletions are treated as one. The last
three blocks of marked text which have been cut (deleted) are also kept and
may be retrieved with paste. Undeleting and pasting are the only undo-like
features I need. Keeping the last three deletions and the last three block
cuts enables those with second thoughts (like me) to be able to retrieve
deletions or cuts they have unwittingly made. Note: undelete and paste do
not remove anything from the list of deletes or cuts. The last three
deletes and and the last three cuts may be undeleted or pasted repeatedly.

Key macros are compiled as Forth words, so they execute very fast. They can
be saved using your system's save-system and thus incorporated into the
editor. There is no provision for user key input in the macro facility so
don't try to exit from the EDITOR to the FORTH command line, or read in a
file while defining a key macro.

All editor words which the user might want for adding extensions to the
editor are contained in the EDITOR vocabulary. Other words are placed in
the HIDDEN vocabulary.

Examples of my key bindings to the various editing functions can be found
in FE.KEY.


Bruce Hoyt, May 2001
Hastings, New Zealand
bhoyt@globe.co.nz
