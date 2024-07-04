" Если вы захотите временно отключить подсветку, вы можете использовать команду:
" :call clearmatches()

" Для повторного включения подсветки используйте команду, которую мы создали:
" :HighlightCyrillicInLatin

" Define the highlight group
highlight CyrillicInLatin ctermbg=red guibg=red

" Function to apply the highlight
function! HighlightCyrillicInLatin()
    call matchadd('CyrillicInLatin', '\v<[a-zA-Z]*[а-яА-Я][a-zA-Z0-9]*>')
endfunction

" Set up autocommands to call the highlight function
augroup HighlightCyrillicInLatinGroup
    autocmd!
    autocmd BufEnter,BufWritePost,TextChanged,InsertLeave * call HighlightCyrillicInLatin()
augroup END

" Command to manually trigger the highlighting
command! HighlightCyrillicInLatin call HighlightCyrillicInLatin()
