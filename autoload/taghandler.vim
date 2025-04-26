" Callback function used by ListFunctions
function! s:ListFunctionsCallback(id, result)
	let function_def_str =  getbufline(winbufnr(a:id), a:result)[0]
	let function_line = split(function_def_str, ':')[0]
	call cursor(function_line, 1)
endfunction

" Function to retrive all functions defined in the current file.
" It will show a list with the result.
function! taghandler#ListFunctions(...)
	let function_regex = '''^[a-zA-Z][a-zA-Z0-9]* \<[a-zA-Z][a-zA-Z0-9_]*[ ]*([[:print:]]*)'''
	let function_list_str = system('grep -n -G '. function_regex . ' ' . expand('%'))

	let function_list = split(function_list_str, '\n')
	if !empty(function_list)
		call popup_menu(function_list, #{callback: 's:ListFunctionsCallback', highlight: '', border: [], padding: [0,0,0,0]})
	endif
endfunction
