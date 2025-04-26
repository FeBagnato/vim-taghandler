" Last Change: 2025 Apr 12
" Mantainer: Felipe Bagnato
" License: GPL

if exists("g:loaded_taghandler")
	finish
endif
let g:loaded_taghandler = 1

command! -nargs=0 DisplayTime call taghandler#DisplayTime()
command! -nargs=0 ListFunctions call taghandler#ListFunctions()
