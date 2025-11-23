" ===========================================================================
" Description: Regex auxiliary variables
" ===========================================================================
let function_regex = '''^[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '\([[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*\)*' .
		\ '[*[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '[[:space:]]*([[:print:]]*)'''

call prop_type_add('separator', {'highlight': 'Operator'})
call prop_type_add('title', {'highlight': 'Title'})
call prop_type_add('type', {'highlight': 'Type'})
" ===========================================================================
" Description: Regex auxiliary functions
" ===========================================================================
let s:func_def = ""
let s:func_name = ""
let s:func_header_file = ""
let s:func_def_list = []
let s:func_doc = []
function! s:GetFunctionInfo(func_def_arg)
    " Verify if it's a actuall definition or a comment
    let grep_list = split(a:func_def_arg, '\n')
    let s:func_def = ""
    for item in grep_list
        echo "[debug] item: " . item
        let item_file = readfile(split(item, ':')[0])
        let item_line = split(item, ':')[1]

        for i in range(item_line - 2, 0, -1)
            if item_file[i] =~ '\*/' || i == 0
                " Valid function
                let s:func_def = item
                break
            endif
            if item_file[i] =~ '/\*'
                " Not a valid function
                break
           endif
        endfor

        if !empty(s:func_def)
            break
        endif
    endfor

    let s:func_def = substitute(s:func_def, ';', '', '')

    let func_split_def_header = split(s:func_def, ':')
    let func_file_line = func_split_def_header[1]
    let s:func_header_file = func_split_def_header[0]
    let s:func_def = func_split_def_header[2]

    " Cases where function declaration is splited into multiple lines
    if s:func_def !~ ')$'
        let func_def_file = readfile(s:func_header_file)
        for i in range(func_file_line -1, len(func_def_file) - 1)
            if func_def_file[i] =~ ';$'
                call add(s:func_def_list, func_def_file[i])
                break
            else
                call add(s:func_def_list, func_def_file[i])
            endif
        endfor
    endif

    echo "[debug] Linux def: " . s:func_def
    echo "[debug] Linux def num: " . func_file_line

    " Save the function name
    let s:func_name = system('echo -n \"' . shellescape(s:func_def) . '\" | grep -o -G [a-zA-Z0-9_]*[[:space:]]*\(')
    let s:func_name = split(s:func_name, '(')[0]

    echo "[debug] Function name: " . s:func_name

    " Get the function documentation (if any)

    let func_doc_file = readfile(s:func_header_file)

    let doc_file_end   = -1
    let doc_file_start = -1

    for i in range(func_file_line - 2, 0, -1)
        " Cases where there is no documentation
        if func_doc_file[i] =~ '^\s*$'
            continue
        endif
        if func_doc_file[i] !~ '\*/'
            " does NOT have documentation
            break
        else
            " HAS documentation
            let doc_file_end   = 0
            let doc_file_start = 0
            break
        endif
    endfor

    if doc_file_end == 0 && doc_file_start == 0
        for i in range(func_file_line - 2, 0, -1)
            " Cases where documentation is written as: /* [function documentation] */
            if func_doc_file[i] =~ '^/\*' && func_doc_file[i] =~ '\*/'
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
            elseif func_doc_file[i] =~ '^/\*'
                let doc_file_start = i
            elseif func_doc_file[i] =~ '^\s*$'
                continue
            else
                if doc_file_end != 0 && doc_file_start != 0
                    break
                endif
            endif
        endfor
    endif

    echo "[debug] Start doc: " . doc_file_start
    echo "[debug] End doc: " . doc_file_end

    for i in range(doc_file_start, doc_file_end)
        let func_doc_fmt = substitute(func_doc_file[i], "/\\*", "", 'g')
        let func_doc_fmt = substitute(func_doc_fmt, "^\\s*", "", '')
        let func_doc_fmt = substitute(func_doc_fmt, "\*/", "", 'g')

        call add(s:func_doc, func_doc_fmt)
    endfor

    " Format header name
    if s:func_header_file !~ '.h$'
        let s:func_header_file = ''
    else
        let func_split_def_header = split(s:func_header_file, '/')
        let s:func_header_file = func_split_def_header[len(func_split_def_header) - 1]
    endif
    echo "[debug] Linux header: " . s:func_header_file

endfunction

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

    let s:func_name = ""
    let s:func_def_list = []
    let s:func_doc = []
    let s:func_header_file = ""
    let func_def_regex = '''^[a-zA-Z_][a-zA-Z0-9_]*' .
    		\ '\([[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*\)*' .
    		\ '[*[:space:]]\+' . cursorSymbol .
    		\ '[[:space:]]*([[:print:]]*'''

    " User functions
    let s:func_def = system('grep -n -G -r ' . func_def_regex . ' . 2>/dev/null')
    if !empty(s:func_def)
        let s:func_def = substitute(s:func_def, ';', '', '')
        let s:func_def = substitute(s:func_def, '{', '', '')
        let s:func_def = split(s:func_def, '\n')[0]

        call s:GetFunctionInfo(s:func_def)
    endif
    echo "[debug] User: " . s:func_def

    " Linux functions
    if empty(s:func_def)
        let s:func_def = system('grep -n -G -r ' . func_def_regex . ' ' . s:linux_include_path . ' --include=*.h ' . ' 2>/dev/null')
        if !empty(s:func_def)
            call s:GetFunctionInfo(s:func_def)
        endif
    endif

    " Showing popup
    let hover_info = []
    let hover_separator = {'text': "---", 'props': [{'col': 1,'length': 3,'type': 'separator'}]}

    let hover_title = {'text': "# Function " . s:func_name, 'props': [{'col': 1,'length': 11,'type': 'title'}]}
    call add(hover_info, hover_title)
    if !empty(s:func_header_file)
        call add(hover_info, {'text': "provided by <" . s:func_header_file . ">"})
    endif

    call add(hover_info, {'text': ""})
    call add(hover_info, hover_separator)

    for line in s:func_doc
        call add(hover_info, {'text': line})
    endfor

    call add(hover_info, hover_separator)

    call add(hover_info, {'text': ""})
    if !empty(s:func_def_list)
        let func_type_len = len(split(s:func_def_list[0], s:func_name)[0])
        let hover_func_def = {'text': s:func_def_list[0], 'props': [{'col': 1,'length': func_type_len,'type': 'type'}]}

        call add(hover_info, hover_func_def)
        for i in range(1, len(s:func_def_list) - 1)
            call add(hover_info, {'text': s:func_def_list[i]})
        endfor
    else
        let func_type_len = len(split(s:func_def, s:func_name)[0])
        let hover_func_def = {'text': s:func_def, 'props': [{'col': 1,'length': func_type_len,'type': 'type'}]}
        call add(hover_info, hover_func_def)
    endif

    let func_popup_id = popup_create(hover_info, #{padding: [1,1,1,1], border: [1,1,1,1], moved: 'any'})

endfunction
