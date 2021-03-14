syntax on

" Autoreload file
set autoread       " automatically reload file when changed on disk

" Persistent Undo
set undofile                  " Save undos after file closes
set undolevels=1000           " How many undos
set undoreload=10000          " number of lines to save for undo
set undodir=$VIMRUNTIME/undos " where to save undo histories

" Miscellaneous
set splitright        " Vertical split goes right, not left
set showcmd           " Show the current command in operator pending mode
set cursorline        " Make the cursor line a visible color
set noshowmode        " Don't show -- INSERT --
set mouse=a           " Allow mouse input
set sidescroll=1      " Number of columns to scroll left and right
set backspace=indent  " allow backspacing only over automatic indenting (:help 'backspace')
set shell=/bin/zsh    " Shell to launch in terminal (see if you can make this built in)
set showtabline=2     " 0 = never show tabline, 1 = when more than one tab, 2 = always
set laststatus=0      " Whether or not to show the status line. Values same as showtabline
set clipboard=unnamed " Use system clipboard
set wildmenu          " Display a menu of all completions for commands when pressing tab

set wrap linebreak breakindent " Don't wrap long lines
set breakindentopt=shift:0,min:20
set formatoptions+=n 

set nofixendofline    " Don't insert an end of line at the end of the file
set noeol             " Give it a mean look so it understands

" Indenting
set tabstop=4 shiftwidth=0 softtabstop=-1 expandtab
set cindent cinoptions=l1,=0,:4,(0,{0

set shortmess=filnxtToOIs

set viminfo+=n$VIMRUNTIME/info " Out of sight, out of mind

set display=lastline " For writing prose
set noswapfile

let s:dot_vim_path = fnamemodify(expand("$MYVIMRC"), ":p:h")

filetype plugin on
colorscheme custom

" Make help window show up on right, not above
augroup MiscFile
    autocmd!
    autocmd FileType help wincmd L
    " Reload _vimrc on write
    " Neither of these work
    autocmd BufWritePost $MYVIMRC  source $MYVIMRC
    autocmd BufWritePost $MYGVIMRC source $MYGVIMRC
augroup END

augroup WrapLines
    autocmd!
    autocmd FileType {txt,org,tex} setlocal wrap linebreak nolist
augroup END

function! s:flat_map(list, transformer)
    call assert_true(type(a:list) == v:t_list)
    let result = []
    for elem in a:list
        let transformed = a:transformer(elem)
        if type(transformed) == v:t_list
            call extend(result, a:transformer(elem))
        else
            echoerr "transformer in flatmap returned value of type " . type(transformed) . ". Expected list."
        endif
    endfor
    return result
endfunction

function! s:filter_list(list, predicate)
    call assert_true(type(a:list) == v:t_list)
    let result = []
    for elem in a:list
        if a:predicate(elem)
            call add(result, elem)
        endif
    endfor
    return result
endfunction

function! s:reduce(initial, list, reducer)
    call assert_true(type(a:list) == v:t_list)
    let result = a:initial
    for elem in a:list
        let result = a:reducer(result, elem)
    endfor
    return result
endfunction

function! AddToPath(...)
    for x in a:000
        if $PATH !~ x
            let $PATH = x . ':' . $PATH
        endif
    endfor
endfunction

call AddToPath('/usr/local/sbin', $HOME . '/bin', '/usr/local/bin')

nnoremap Y y$

" Tab shortcuts
nnoremap <silent> gce :tabnew<CR>
nnoremap <silent> ge  :vnew \| wincmd H<CR>

function! MoveTab(multiplier, count)
    let l:amount  = a:count ? a:count : 1
    let l:cur_tab = tabpagenr()
    let l:n_tabs  = tabpagenr("$")

    let l:new_place = l:cur_tab + a:multiplier * l:amount

    if l:new_place <= 0
        let l:amount = l:cur_tab - 1
    elseif l:new_place > l:n_tabs
        let l:amount = l:n_tabs - l:cur_tab
    endif

    if l:amount != 0
        let l:cmd = 'tabmove '

        if a:multiplier > 0
            let l:cmd .= '+'
        endif

        let l:cmd .= a:multiplier * l:amount
        " echo "Moving Tabs " . l:cmd
        exec l:cmd
    endif
endfunction

nnoremap <silent> g{ :<C-U>call MoveTab(-1, v:count)<CR>
nnoremap <silent> g} :<C-U>call MoveTab(+1, v:count)<CR>

function! ReenterVisual()
    normal! gv
endfunction

function! GotoBeginningOfLine()
    if indent(".") + 1 == col(".")
        normal! 0
    else
        normal! ^
    endif
endfunction

nnoremap <silent> 0 :<C-U>call GotoBeginningOfLine()<CR>
nnoremap <silent> - $

vnoremap <silent> 0 :<C-U>call ReenterVisual() \| call GotoBeginningOfLine()<CR>
vnoremap <silent> - $

onoremap <silent> 0 :<C-U>call GotoBeginningOfLine()<CR>
onoremap <silent> - $

" Some terminal shortcuts
nnoremap <silent> ght :vertical terminal<CR>
nnoremap <silent> gct :tabnew \| terminal++curwin<CR>

if !has('win32')
    " Debugger
    let s:debugger = "lldb"
    function! LaunchDebugger(vertical, options)
        if a:vertical
            let prev_command = "vertical"
        else
            let prev_command = "tabnew \|"
        endif
        exe prev_command . " terminal " . a:options . " ++noclose " . s:debugger
    endfunction
    nnoremap <silent> ghd :call LaunchDebugger(1, "")<CR>
    nnoremap <silent> gcd :call LaunchDebugger(0, "++curwin")<CR>

    " Htop
    nnoremap <silent> ghh :vertical terminal htop<CR>
    nnoremap <silent> gch :tabnew \| terminal++curwin htop<CR>
endif

" Enter normal mode without getting emacs pinky
tnoremap <C-w>[ <C-\><C-n>
tnoremap <C-w><C-[> <C-\><C-n>

function! RebalanceCurrentBlock()
    let open_pos = getpos(".")
    let indent_before = indent(".")

    normal! =%

    let open_pos[2] += indent(".") - indent_before
    call setpos(".", l:open_pos)
endfunction

" Autocomplete blocks
inoremap          {<CR> {<CR>}<Esc>=kox<BS>
inoremap <silent> } }<Esc>%:call RebalanceCurrentBlock()<CR>%a

" Useless Keys
nnoremap <CR>    <nop>
nnoremap <BS>    <nop>
nnoremap <Del>   <nop>
nnoremap <Space> <nop>

" Who needs Ex-mode these days?
nnoremap Q <nop>

" Terminal movement in command line mode
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
cnoremap <C-a> <C-b>
" cnoremap <C-e> <C-e> " already exists
cnoremap <C-d> <Del>

" Move selected lines up and down
vnoremap <C-J> :m '>+1<CR>gv=gv
vnoremap <C-K> :m '<-2<CR>gv=gv

nnoremap <C-J> zl
nnoremap <C-H> zh

" Commands for convenience
command! -bang -complete=file W w<bang> <args>
command! -bang Q q<bang>
command! -bang -nargs=? -complete=file E e<bang> <args>

" Leader mappings
let mapleader = " "

function! ToggleLineNumbers()
    set norelativenumber!
    set nonumber!
endfunction
nnoremap <leader>n :call ToggleLineNumbers()<CR>

let s:comment_leaders = {
    \ 'c' : '//',
    \ 'cpp' : '//',
    \ 'vim' : '"',
    \ 'python' : '#'
\ }
    
function! RemoveCommentLeadersNormal(count)
    if has_key(s:comment_leaders, &filetype)
        let leader = substitute(s:comment_leaders[&filetype], '\/', '\\/', 'g')

        let cur_pos = getpos(".")
        let current_line = cur_pos[1]

        if getline(current_line) =~ '^\s*' . leader
            let lastline = current_line + (a:count == 0 ? 1 : a:count)
            let command = (current_line+1) . "," . lastline . 's/^\s*' . leader . "\s*//e"
            exec command
        endif

        call setpos(".", cur_pos)

    endif
    exec "normal! " . (a:count+1) . "J"
endfunction

function! RemoveCommentLeadersVisual() range
    if has_key(s:comment_leaders, &filetype)
        let leader = substitute(s:comment_leaders[&filetype], '\/', '\\/', 'g')
        " echo leader
        if getline(a:firstline) =~ '^\s*' . leader
            let command = (a:firstline+1) . "," . a:lastline . 's/^\s*' . leader . '\s*//e'
            exec command
        endif

        normal! gvJ
        " echo command
    endif
endfunction
vnoremap <silent> J :call RemoveCommentLeadersVisual()<CR>
nnoremap <silent> J :<C-U>call RemoveCommentLeadersNormal(v:count)<CR>

augroup EnterAndLeave
    " Enable and disable cursor line in other buffers
    autocmd!
    autocmd     WinEnter * set   cursorline | redrawtabline
    autocmd     WinLeave * set nocursorline | redrawtabline
    autocmd  InsertEnter * set nocursorline | redrawtabline
    autocmd  InsertLeave * set   cursorline | redrawtabline

    autocmd CmdlineEnter *                    redrawtabline
    autocmd CmdlineLeave *                    redrawtabline

    " autocmd CmdlineEnter / call OverrideModeName("Search") | redrawtabline
    " autocmd CmdlineLeave / call OverrideModeName(0) | redrawtabline

    " autocmd CmdlineEnter ? call OverrideModeName("Reverse Search") | redrawtabline
    " autocmd CmdlineLeave ? call OverrideModeName(0) | redrawtabline

    " I created these but they don't work as intended yet
    " autocmd  VisualEnter *                    redrawtabline
    " autocmd  VisualLeave *                    redrawtabline
augroup END

" =============================================
" Style changes

" Change cursor shape in different mode (macOS default terminal)
" For all cursor shapes visit
" http://vim.wikia.com/wiki/Change_cursor_shape_in_different_modes
"                 Blink   Static
"         block ¦   1   ¦   2   ¦
"     underline ¦   3   ¦   4   ¦
" vertical line ¦   5   ¦   6   ¦

let &t_SI.="\e[6 q" " Insert mode
let &t_SR.="\e[4 q" " Replace mode
let &t_EI.="\e[2 q" " Normal mode

" Directory tree listing options
let g:netrw_liststyle = 1
let g:netrw_banner = 0

" Docs: http://vimhelp.appspot.com/eval.txt.html
set fillchars=stlnc:\|,vert:\|,fold:.,diff:.

" let s:mode_name_override = 0
" function! OverrideModeName(name)
"     let s:mode_name_override = a:name
" endfunction

let s:current_mode = {
    \ 'n'  : 'Normal',
    \ 'i'  : 'Insert',
    \ 'v'  : 'Visual',
    \ 'V'  : 'Visual Line',
    \ '' : 'Visual Block',
    \ 'R'  : 'Replace',
    \ 'c'  : 'Command Line',
    \ 't'  : 'Terminal'
\ }

function! GetCurrentMode()
    " if s:mode_name_override isnot 0
    "     return s:mode_name_override
    " else

    return get(s:current_mode, mode(), mode())

    " endif
endfunction


" Hours (24-hour clock) followed by minutes
let s:timeformat = has('win32') ? '%H:%M' : '%k:%M'

" Custom tabs
function! Tabs() abort
    " NOTE: getbufinfo() gets all variables of all buffers
    " Colours
    let l:cur_tab_page = tabpagenr()
    let l:n_tabs = tabpagenr("$")
    let l:max_file_name_length = 30

    " NOTE: Repeat is used to pre-allocate space, make sure that this is the
    " correct number of characters, otherwise you'll get an error
    let l:num_prefixes = 3
    let l:strings_per_tab = 7
    let l:s = repeat(['EMPTY!!!'], l:num_prefixes + l:n_tabs * l:strings_per_tab + 3)

    " TODO: Make this a different colour
    let l:s[0] = " "
    let l:s[1] = GetCurrentMode()
    let l:s[2] = " "
    " Previously this was initialized to an empty list and I was using
    " extend() to add elements
    " let l:s = [] " Not sure if a list is faster than a string but there is no stringbuilder in vimscript

    for i in range(l:n_tabs)
        let l:n = i + 1
        let l:bufnum = tabpagebuflist(l:n)[tabpagewinnr(l:n) - 1]

        " %<num>T specifies the beginning of a tab
        let l:s[l:num_prefixes + i * l:strings_per_tab + 0] = "%"
        let l:s[l:num_prefixes + i * l:strings_per_tab + 1] = l:n

        let l:s[l:num_prefixes + i * l:strings_per_tab + 2] = n == l:cur_tab_page ? "T%#TabLineSel# " : "T%#TabLine# "

        let l:s[l:num_prefixes + i * l:strings_per_tab + 3] = l:n

        " '-' for non-modifiable buffer, '+' for modified, ':' otherwise
        let l:modifiable = getbufvar(l:bufnum, "&modifiable")
        let l:modified   = getbufvar(l:bufnum, "&modified")
        let l:s[l:num_prefixes + i * l:strings_per_tab + 4] = !l:modifiable ?  "- " : l:modified ? "* " : ": "

        let l:name = bufname(l:bufnum)
        let l:s[l:num_prefixes + i * l:strings_per_tab + 5] = l:name == "" ? "[New file]" : (len(l:name) >= l:max_file_name_length ? "<" . l:name[-l:max_file_name_length:] : l:name)

        let l:s[l:num_prefixes + i * l:strings_per_tab + 6] = " "
    endfor

    " %= is the separator between left and right side of tabline
    " %T specifies the end of the last tab
    let l:s[-3] = "%T%#TabLineFill#%=%#TabLineSel# "
    let l:s[-2] = strftime(s:timeformat)
    let l:s[-1] = ' '

    return join(l:s, "")
endfunction

" Can type unicode codepoints with C-V u <codepoint> (ex. 2002)
" Maybe put the tabs in the status bar or vice-versa (probably better in the
" tab bar so that information is not duplicated
function! StatusLine() abort
    let winnum = winnr() " tabpagebuflist(l:n)[tabpagewinnr(l:n) - 1]
    let bufnum = winbufnr(l:winnum)
    let name   =  bufname(l:bufnum)

    let result  = ""

    if bufnum == bufnr("%")
        let result .= " " . GetCurrentMode()
    endif

    " let result .= " " . l:winnum 
    let result .= " > " . l:name
    let filetype = getbufvar(l:bufnum, "&filetype")
    if len(l:filetype) != 0
        let result .= " " . l:filetype
    endif

    let modifiable = getbufvar(l:bufnum, "&modifiable")
    let modified   = getbufvar(l:bufnum, "&modified")
    let result .= !l:modifiable ? " -" : l:modified ? " +" : ""

    return l:result . " "
endfunction

set statusline=%!StatusLine()
set tabline=%!Tabs()

call timer_stopall()
function! RedrawTabLineRepeated(timer)
    " Periodically redraw the tabline so that the current time is correct
    " echo "Redrawing tab line repeated " . strftime('%H:%M:%S')
    redrawtabline
endfunction
function! RedrawTabLineFirst(timer)
    " The first redraw of the tab line so that it updates on the minute
    " echo "Redrawing tab line first " . strftime('%H:%M:%S')
    redrawtabline
    call timer_start(1 * 1000 * 60, 'RedrawTabLineRepeated', {'repeat':-1})
endfunction

" On some systems the time returned by reltime() is a few seconds off
let s:time_difference_seconds = str2nr(strftime('%S')) - (float2nr(reltimefloat(reltime())) % 60)
let s:timeUntilNextMinute = 60 - ((float2nr(reltimefloat(reltime())) + s:time_difference_seconds) % 60)
call timer_start(s:timeUntilNextMinute * 1000, 'RedrawTabLineFirst')

" ============================================
" Color Additions
" Highlighting in comments

" NOTE: Reloading causes tests above to stop working, just use :e to reload
" the file
augroup my_todo
    autocmd!
    autocmd Syntax *
        \   syn keyword CustomYellow     containedin=[a-zA-Z]*CommentL\? TODO OPTIMIZE HACK
        \ | syn keyword CustomGreen      containedin=[a-zA-Z]*CommentL\? NOTE INCOMPLETE
        \ | syn keyword CustomRed        containedin=[a-zA-Z]*CommentL\? XXX FIX FIXME BUG IMPORTANT
        \ | syn keyword CustomBlue       containedin=[a-zA-Z]*CommentL\? REVIEW SIMPLIFY
        \ | syn region  CustomRed        containedin=[a-zA-Z]*CommentL\? start='![_a-zA-Z0-9]'  end='\>'
        \ | syn region  CustomGreen      containedin=[a-zA-Z]*CommentL\? start='@[_a-zA-Z0-9]'  end='\>'
        \ | syn region  CustomYellow     containedin=[a-zA-Z]*CommentL\? start='#[_a-zA-Z0-9]'  end='\>'
        \ | syn region  CustomBlue       containedin=[a-zA-Z]*CommentL\? start='\$[_a-zA-Z0-9]' end='\>'
        " \ | syn region  CustomOrange     containedin=[a-zA-Z]*CommentL\? start='&[_a-zA-Z0-9]'  end='\>'
        " \ | syn region  CustomHotPink    containedin=[a-zA-Z]*CommentL\? start=':[_a-zA-Z0-9]'  end='\>'
        " \ | syn region  CustomPurple     containedin=[a-zA-Z]*CommentL\? start='/[_a-zA-Z0-9]'  end='\>'
        \
        \ | syn region  CustomRed        containedin=[a-zA-Z]*CommentL\? start='!\['  end='\]\|$'
        \ | syn region  CustomGreen      containedin=[a-zA-Z]*CommentL\? start='@\['  end='\]\|$'
        \ | syn region  CustomYellow     containedin=[a-zA-Z]*CommentL\? start='#\['  end='\]\|$'
        \ | syn region  CustomBlue       containedin=[a-zA-Z]*CommentL\? start='\$\[' end='\]\|$'
        \ | syn region  CustomDarkBlue   containedin=[a-zA-Z]*CommentL\? start='%\['  end='\]\|$'
        " \ | syn region  CustomOrange     containedin=[a-zA-Z]*CommentL\? start='&\['  end='\]\|$'
        " \ | syn region  CustomHotPink    containedin=[a-zA-Z]*CommentL\? start=':\['  end='\]\|$'
        " \ | syn region  CustomPurple     containedin=[a-zA-Z]*CommentL\? start='/\['  end='\]\|$'

        " These would be interesting in comments but they also match outside
        " of comments and that's annoying.
        " \ | syn region  CustomBold      containedin=[a-zA-Z]*CommentL\? contains=CustomUnderline start='*'  end='*\|$'
        " \ | syn region  CustomUnderline containedin=[a-zA-Z]*CommentL\? contains=CustomBold      start='\<_' end='_\|$'
        " \ | syn region  NONE matchgroup=CustomBlockBlue containedin=[a-zA-Z]*CommentL\? contains=Custom.* start='\\[_a-zA-Z0-9]\+{'   end='}'
augroup END

" Fruit salad for testing
"     FIX - FIXME - TODO - NOTE - XXX - OPTIMIZE - INCOMPLETE - BUG - HACK - REVIEW - SIMPLIFY
"     !Exclamation --- @AtSign --- #Hash --- $Dollar --- %Percent
"     &Ampersand
"     /Slash --- :Colon
"     
"     [[abc def]] {{abc def}}

" cterm colours are not correct
hi CustomRed         guifg=#eb4034 guibg=NONE ctermfg=160  ctermbg=NONE gui=none      cterm=none
hi CustomYellow      guifg=#d7d7af guibg=NONE ctermfg=187  ctermbg=NONE gui=none      cterm=none
hi CustomGreen       guifg=#55bd53 guibg=NONE ctermfg=112  ctermbg=NONE gui=none      cterm=none
hi CustomBlue        guifg=#33c0d6 guibg=NONE ctermfg=153  ctermbg=NONE gui=none      cterm=none
hi CustomOrange      guifg=#e54f00 guibg=NONE ctermfg=166 ctermbg=NONE gui=none cterm=none
hi CustomDarkBlue    guifg=#5f87ff guibg=NONE ctermfg=69  ctermbg=NONE gui=none cterm=none
hi CustomHotPink     guifg=#d75faf guibg=NONE ctermfg=169 ctermbg=NONE gui=none cterm=none
hi CustomPurple      guifg=#950087 guibg=NONE ctermfg=90  ctermbg=NONE gui=none cterm=none

" ============================================
" Common variables that may be needed by other functions
let s:path_separator = has('win32') ? '\' : '/'

function! CreateSourceHeader()
    let file_name = expand('%:t')
    let file_extension = split(file_name, '\.')[1]
    let date = strftime("%d %B %Y")
    let year = strftime("%Y")
    
    let header = ['/*',
                \ '  File: ' . file_name,
                \ '  Date: ' . date,
                \ '  Creator: Alexandru Filip',
                \ '  Notice: (C) Copyright ' . year . ' by Alexandru Filip. All rights reserved.',
                \ '*/',
                \ ]
                " \ '// ',

    call append(0, header)

    if file_extension =~ '^[hH].*$'
        let modified_filename = toupper(file_name)
        let modified_filename = substitute(modified_filename, '[^A-Z]', '_', 'g')

        let header = [
                    \ '#ifndef ' . modified_filename,
                    \ '#define ' . modified_filename,
                    \ '',
                    \ '',
                    \ '',
                    \ '#endif',
                    \ ]
        call append(line("$"), header)

        let pos = getpos("$")
        let pos[1] -= 2
        call setpos(".", pos)
    endif
endfunction

augroup FileHeaders
    autocmd!
    autocmd BufNewFile *.c,*.cpp,*.h,*.hpp call CreateSourceHeader()
augroup END

" ============================================
"  Terminal commands
" ============================================

" Search for a script named "build.bat" moving up from the current path and run it.
" TODO: find out how to compile through vim on windows
let s:compile_script_name = has('win32') ? 'build.bat' : './compile'
let s:shell = has('win32') ? '++shell' : '/bin/zsh -c'

function! IsTerm()
    return get(getwininfo(bufwinid(bufnr()))[0], 'terminal', 0)
endfunction

function! SwitchToOtherPaneOrCreate()
    let l:start_win = winnr()
    let l:layout = winlayout()
    if l:layout[0] == 'leaf'
        " Create new vertical pane and go to left one
        wincmd v
        wincmd l
    elseif l:layout[0] == 'row'
        " Buffers layed out side by side
        wincmd l
        if winnr() == l:start_win
            wincmd h
        endif
    elseif l:layout[0] == 'col'
        " Buffers layed out one on top of the other
        wincmd j
        if winnr() == l:start_win
            wincmd k
        endif
    endif
endfunction

function! GotoLineFromTerm()
    if IsTerm()
        let line_contents = getline(".")
        let regex = '^[A-Za-z0-9/\-\.]\+:[0-9]\+:[0-9]\+:'

        if match(line_contents, regex) != -1
            let components = split(line_contents, ":")
            let filepath = components[0]
            let line_num = components[1]
            let col_num  = components[2]

            call SwitchToOtherPaneOrCreate()
            " NOTE: Might need to save current file
            exe "edit " . filepath
            call setpos(".", [0, line_num, col_num, 0])
            normal! zz
        else
            echo "Line does not match known error message format (" . regex . ")"
        endif

    endif
endfunction

function! DoCommandsInTerm(commands)
    " Currently, this assumes you only have one split and uses only the top-most
    " part of the layout as the guide.

    " NOTE: The problem with this is that a terminal in a split that is not
    " right beside the current one will not be reused. This will create a new
    " terminal.

    if !IsTerm()
        call SwitchToOtherPaneOrCreate()
    endif
    exe "term++noclose ++curwin " . s:shell . ' "' . join(a:commands, " && ") . '"'
endfunction

function! SearchAndCompile()
    let l:working_dir = split(getcwd(), s:path_separator)
    while len(l:working_dir) > 0
        let l:directory_path = s:path_separator . join(l:working_dir, s:path_separator)
        if executable(l:directory_path . s:path_separator . s:compile_script_name)
            " One problem with this is that I can't scroll through the
            " history to see all the errors from the beginning
            call DoCommandsInTerm(["cd " . l:directory_path, s:compile_script_name, "echo Compiled Successfully"])
            return
        endif
        let l:working_dir = l:working_dir[:-2] " remove last path element
    endwhile
    echo "No file named \"" . s:compile_script_name . "\" found"
endfunction

nnoremap <silent> <leader>g :call GotoLineFromTerm()<CR>
nnoremap <silent> <leader>c :call SearchAndCompile()<CR>

function! RenameFiles()
    let l:file_list = split(system("ls"), '\n')

    " Empty lines are allowed
    let l:lines = filter(getline(1, '$'), {idx, val -> len(val) > 0})
    if len(l:lines) != len(l:file_list)
        echoerr "Number of lines in buffer (" . len(l:lines) .
              \ ") does not match number of files in current directory (" . 
              \ len(l:file_list) . ")"

        return
    endif

    let l:commands = repeat([''], len(l:file_list))
    for index in range(len(l:file_list))
        " TODO: replace characters that need escaping with \char
        let l:commands[index] = "mv \"" . l:file_list[index] . "\" \"" . l:lines[index] . "\""
    endfor

    normal ggdG
    put =l:commands

    " I would still have to make sure that all of the appropriate characters
    " in the filename, like quotes, are escaped.
    "
    " Start by running :r !ls
    " Change names within the document
    " Run :w !zsh after this (use your shell of choice. Can get this with &shell)
endfunction
command! RenameFiles :call RenameFiles()

let s:projects_folder="~/projects"
function! ProjectsCompltionList(ArgLead, CmdLine, CursorPos)
    let result = []
    let arg_match = "^" . a:ArgLead . ".*"

    for path in split(globpath(s:projects_folder, "*"), "\n")
        if isdirectory(path)
            let folder_name = split(path, "/")[-1]
            if folder_name =~ arg_match
                call add(result, folder_name)
            endif
        endif
    endfor

    return result
endfunction

function! GoToProjectOrMake(bang, path)
    exec "cd " . s:projects_folder
    if !isdirectory(a:path)
        if filereadable(a:path)
            if a:bang
                call delete(a:path)
            else
                echoerr a:path . " exists and is not a directory. Use Project! to replace it with a new project."
                return
            endif
        endif
        echo a:path . " does not exist. Creating."
        call mkdir(a:path)
    endif

    exec "cd " . a:path
    edit .
endfunction
command! -bang -nargs=1 -complete=customlist,ProjectsCompltionList  Project :call GoToProjectOrMake(<bang>0, <q-args>)

function! WritingMode(parent_dir)
    if len(a:parent_dir) > 0
        let l:date = strftime("%e %b %Y") " Ex. 12 Aug 2020
        let l:command = (bufname("%") == "" && !getbufvar("%", '&modified') ? 'edit ' : 'tabnew ') .
                        \ (a:parent_dir. l:date . '.txt')
        cd a:parent_dir
    endif

    execute l:command
    setlocal wrap linebreak
    setlocal noundofile undolevels=0 undoreload=0
    setlocal foldmethod=indent
endfunction

command! Writing call WritingMode('')
command! Journal call WritingMode('~/Documents/Notes/Journal/')

" Todo list and log of the day
function! Log()

    let l:start_win = winnr()
    let l:layout = winlayout()
    let l:command = (bufname("%") == "" &&
                    \ !getbufvar("%", '&modified') ) ? 'edit' : 'tabnew'

    execute l:command . ' ~/Documents/Notes/Daily-Log/Log-' . strftime("%e-%b-%Y") . '.txt'
    
    " Don't automatically reformat when I type special characters
    setlocal cinkeys=
    " When wrapping, indent by 7 characters, the length of the timestamp.
    setlocal breakindentopt+=shift:8

    nnoremap <silent> <buffer> o :call append(line("."), strftime("%H:%M \| "))<CR>jA
    inoremap <silent> <buffer> <CR> <Esc>:call append(line("."), strftime("%H:%M \| "))<CR>jA

    nnoremap <buffer> j gj
    nnoremap <buffer> k gk

endfunction
command! Log call Log()


call plug#begin(s:dot_vim_path . '/plugins')

Plug 'junegunn/vim-easy-align'
Plug 'keith/swift.vim'
Plug 'rust-lang/rust.vim'
Plug 'vim-utils/vim-man'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-fugitive'

call plug#end()