" Last Change: 2025 Mai 1
" Mantainer: Felipe Bagnato
" License: GPL

if exists("g:loaded_taghandler")
	finish
endif
let g:loaded_taghandler = 1

" Commands
command! -nargs=0 ListFunctions call taghandler#search#ListFunctions()
command! -nargs=0 TagFind call taghandler#search#Find()
command! -nargs=0 TagFindJumpBackwards call taghandler#search#FindJumpBackwards()
command! -nargs=0 TagHover call taghandler#hover#FunctionHover()
