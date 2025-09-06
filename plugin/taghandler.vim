" Last Change: 2025 Mai 1
" Mantainer: Felipe Bagnato
" License: GPL

if exists("g:loaded_taghandler")
	finish
endif
let g:loaded_taghandler = 1

" Commands
command! -nargs=0 ListFunctions call taghandler#ListFunctions()

" Mappings
nnoremap <silent> tf  :call taghandler#Find()<CR>
nnoremap <silent> tls :call taghandler#ListFunctions()<CR>
nnoremap <silent> tjb :call taghandler#FindJumpBackwards()<CR>
