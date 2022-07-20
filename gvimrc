vim9script
" augroup Startup
"     autocmd!
"     autocmd GUIEnter * 
" augroup END

set guioptions=

if has('win32')
    augroup StartupWin32
        autocmd!
        autocmd GUIEnter * simalt ~x | cd ~\ | set guifont=Hack:h13
    augroup END
else
    " augroup StartupUnixMac
    "     autocmd!
    "     autocmd GUIEnter * 
    " augroup END
    set guifont=Source\ Code\ Pro\ Light:h16
endif
