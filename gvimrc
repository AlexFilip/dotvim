set guioptions=

if has('win32')
    set guifont=Hack:h14
    au GUIEnter * simalt ~x
else
    set guifont=Source\ Code\ Pro\ Light:h16
endif
