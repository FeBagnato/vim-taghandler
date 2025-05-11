" Callback function used by ListFunctions
function! s:ListFunctionsCallback(id, result)
	if a:result < 0
		return 1
	endif

	let function_def_str =  getbufline(winbufnr(a:id), a:result)[0]
	let function_line = split(function_def_str, ':')[0]
	call cursor(function_line, 1)
	return 0
endfunction

" Name: ListFunctions
" Description: Function to retrive all functions defined in the current file.
"              It will show a list with the result.
" Return: None
function! taghandler#ListFunctions(...)
	if v:version < 900
		echo "You need to use vim 9.0 or newer"
		return
	endif

	let function_regex = '''^[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '\([[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*\)*' .
		\ '[*[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*' .
		\ '[[:space:]]*([[:print:]]*)'''
	let function_list_str = system('grep -n -G '. function_regex . ' ' . expand('%'))
	let function_list_str = substitute(function_list_str, '\s\+', ' ', 'g')

	let function_list = split(function_list_str, '\n')
	if !empty(function_list)
		call popup_menu(function_list, #{callback: 's:ListFunctionsCallback', highlight: '', border: [], padding: [0,0,0,0]})
	endif
endfunction


" Callback function used by Find
function! s:FindCallback(id, result)
	if a:result < 0
		return 1
	endif

	let function_location = split(getbufline(winbufnr(a:id), a:result)[0], ':')
	if function_location[0] == expand('%')
		call cursor(function_location[1], 1)
	else
		execute 'tabe ' . function_location[0]
		call cursor(function_location[1], 1)
	endif

	return 0
endfunction

" Name: Find
" Description: Function to find all symbol references inside a project.
"              It will show a list with the location of the symbols on which the cursor
"              is under.
" Return: None
function! taghandler#Find()
	if v:version <	900
		echo "You need to use vim 9.0 or newer"
		return
	endif

	let cursorSymbol = expand('<cword>')
	if empty(cursorSymbol)
		return
	endif

	let function_list_str = system('grep -n -r '. cursorSymbol . ' ' . '* 2>/dev/null')
	let function_list_str = substitute(function_list_str, '\s\+', ' ', 'g')
	let function_list = split(function_list_str, '\n')
	call popup_menu(function_list, #{callback: 's:FindCallback', highlight: '', border: [], padding: [0,0,0,0]})
endfunction


" Name: GetCurrentFunction
" Description: This function will show the current function name.
"              It can be called in .vimrc to always show this information in statusline.
" Return: None
let s:current_function_value = ""
function! s:GetCurrentFunction(...)
	let function_regex = "^[a-zA-Z_][a-zA-Z0-9_]*" .
		\ "\\([ \t]\\+[a-zA-Z_][a-zA-Z0-9_]*\\)*" .
		\ "[* \t]\\+[a-zA-Z_][a-zA-Z0-9_]*" .
		\ "[ \t]*(.*)"
	let last_function_definition =  search(function_regex, 'bWnc')
	let last_end_of_function = search("^}", 'bWn')

	if last_function_definition > last_end_of_function
		let function_definition_line = getline(last_function_definition)
		let function_definition_splited = split(function_definition_line, '(')[0]

		if function_definition_splited =~ '\s'
			let function_definition_no_spaces = split(function_definition_splited)
			let s:current_function_value = function_definition_no_spaces[len(function_definition_no_spaces) - 1]
		else
			" In case the function name is something like "void**function()" which is valid in C"
			let function_name_start_position = stridx(function_definition_splited, '*')
			let s:current_function_value = function_definition_splited[function_name_start_position:]
		endif
	else
		let s:current_function_value = ""
	endif
endfunction

" GetCurrentFunction entry point
let s:first_run = 1
function! taghandler#ReturnCurrentFunction()
		if s:first_run
			call timer_start(0, 's:GetCurrentFunction', {'repeat': -1})
			let s:first_run = 0
		endif

		return s:current_function_value
endfunction
