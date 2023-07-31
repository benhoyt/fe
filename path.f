\ PATH  --  Path routines   								17-02-99 09:02:43

in-editor

0 [if]

The non-standard expand-path is used in wild-card expansion and also to
locate the master configuration file if one is not found in the current
directory.

The non-standard get-prog-name is used to locate the master configuration
file if one is not found in the current directory.

These can be removed by setting allow-expand-path and allow-prog-name to
false.

[then]

allow-expand-path [if]  	\ compiler option

: get-full-path ( fname dest -- )   	\ return full path name of fname
	>r count r> 1+ expand-path >int-sep ( dest+1 cnt )
	swap 1- c! ;

[else]

: get-full-path ( fname dest -- )   	\ return full path name of fname
	$move ;

[then] \ allow-expand-path

allow-prog-name [if]

: get-prog-path ( -- addr len ) 	\ return program path, include trailing '\'
	program-name path-only ;

[then] \ allow-prog-name
