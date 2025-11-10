" ===========================================================================
" Description: Regex auxiliary variables
" ===========================================================================
let function_regex = '''^[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '\([[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*\)*' .
		\ '[*[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '[[:space:]]*([[:print:]]*)'''

" ===========================================================================
" Name: FunctionHover
" Description: This function will show a function declaration and it's
" documentation (if available).
" Return: None
" ===========================================================================
let s:linux_include_path = "/usr/include/"
function! taghandler#hover#FunctionHover(...)
	if v:version <	900
		echo "You need to use vim 9.0 or newer"
		return
	endif

    let cursorSymbol = expand('<cword>')
    if empty(cursorSymbol)
        return
    endif

    let func_def_regex = '''^[a-zA-Z_][a-zA-Z0-9_]*' .
    		\ '\([[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*\)*' .
    		\ '[*[:space:]]\+' . cursorSymbol .
    		\ '[[:space:]]*([[:print:]]*)'''

    " User functions
    let func_def = system('grep -G ' . func_def_regex . ' ' . expand('%'))
    let func_def = substitute(func_def, ';', '', '')
    let func_def = substitute(func_def, '{', '', '')
    echo "[debug] User: " . func_def

    " Linux functions
    let func_header_file = ""
    if empty(func_def)
        let func_def = system('grep -G -r ' . func_def_regex . ' ' . s:linux_include_path . ' --include=*.h ' . ' 2>/dev/null')
        if !empty(func_def)
            let func_def = substitute(func_def, ';', '', '')

            let func_split_def_header = split(func_def, ':')
            let func_header_file = func_split_def_header[0]
            let func_def = func_split_def_header[1]
            echo "[debug] Linux def: " . func_def
            echo "[debug] Linux header: " . func_header_file
        endif
    endif

endfunction
