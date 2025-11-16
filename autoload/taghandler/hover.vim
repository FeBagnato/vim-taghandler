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
    let func_file_line = 0
    if empty(func_def)
        let func_def = system('grep -n -G -r ' . func_def_regex . ' ' . s:linux_include_path . ' --include=*.h ' . ' 2>/dev/null')
        if !empty(func_def)
            let func_def = substitute(func_def, ';', '', '')

            let func_split_def_header = split(func_def, ':')
            let func_file_line = func_split_def_header[1]
            let func_header_file = func_split_def_header[0]
            let func_def = func_split_def_header[2]
        endif
    endif
    echo "[debug] Linux def: " . func_def
    echo "[debug] Linux def num: " . func_file_line
    echo "[debug] Linux header: " . func_header_file

    " Save the function name
    let func_name = system('echo -n \"' . shellescape(func_def) . '\" | grep -o -G [a-zA-Z0-9_]*[[:space:]]*\(')
    let func_name = split(func_name, '(')[0]

    echo "[debug] Function name: " . func_name

    " Get the function documentation (if any)

    let func_doc_file = readfile(func_header_file)

    let doc_file_end   = 0
    let doc_file_start = 0
    for i in range(func_file_line - 2, 0, -1)
        " Cases where documentation is written as: /* [function documentation] */
        if func_doc_file[i] =~ '/\*' && func_doc_file[i] =~ '\*/'
            let doc_file_start = i
            let doc_file_end = i
            break
        endif

        " Cases where documentation is written as:
        " /*
        "    [function documentation]
        " */
        if func_doc_file[i] =~ '\*/'
            if doc_file_end == 0
                let doc_file_end = i
            endif
        elseif func_doc_file[i] =~ '/\*'
            let doc_file_start = i
        elseif func_doc_file[i] =~ '^\s*$'
            continue
        else
            if doc_file_end != 0 && doc_file_start != 0
                break
            endif
        endif
    endfor

    echo "[debug] Start doc: " . doc_file_start
    echo "[debug] End doc: " . doc_file_end

    let func_doc = []
    for i in range(doc_file_start, doc_file_end)
        call add(func_doc, func_doc_file[i])
    endfor

    " Showing popup
    let hover_info = []

    call add(hover_info, "# Function " . func_name)
    call add(hover_info, "provided by <" . func_header_file . ">")

    call add(hover_info, "")
    call add(hover_info, "---")
    let hover_info = hover_info + func_doc
    call add(hover_info, "---")

    let func_popup_id = popup_create(hover_info, #{padding: [1,1,1,1], border: [1,1,1,1]})

endfunction
