syntax on

" Autoreload file
set autoread " automatically reload file when changed on disk

" Persistent Undo
set undofile                  " Save undos after file closes
set undolevels=1000           " How many undos
set undoreload=10000          " number of lines to save for undo
set undodir=$HOME/.local/vim-undos " where to save undo histories

let s:undo_dir = expand("~/.local/vim-undos/")
if !isdirectory(s:undo_dir)
    call mkdir(s:undo_dir)
endif

" Miscellaneous
set splitright        " Vertical split goes right, not left
set showcmd           " Show the current command in operator pending mode
set cursorline        " Make the cursor line a visible color
set noshowmode        " Don't show -- INSERT --
set mouse=a           " Allow mouse input
set sidescroll=1      " Number of columns to scroll left and right
set backspace=indent  " allow backspacing only over automatic indenting (:help 'backspace')
set showtabline=2     " 0 = never show tabline, 1 = when more than one tab, 2 = always
set laststatus=0      " Whether or not to show the status line. Values same as showtabline
set clipboard=unnamed " Use system clipboard
set wildmenu          " Display a menu of all completions for commands when pressing tab

set wrap linebreak breakindent " Wrap long lines
set breakindentopt=shift:0,min:20
set formatoptions+=n 
set virtualedit=block " Visual block mode is not limited to the character locations

set nofixendofline    " Don't insert an end of line at the end of the file
set noeol             " Give it a mean look so it understands

if !has('win32') && executable('/bin/zsh')
    set shell=/bin/zsh " Shell to launch in terminal
endif

" Indenting
set tabstop=4 shiftwidth=0 softtabstop=-1 expandtab
set cindent cinoptions=l1,=0,:4,(0,{0,+2,w1,W4,t0
set shortmess=filnxtToOIs

set viminfo+=n$VIMRUNTIME/info " Out of sight, out of mind

set display=lastline " For writing prose
set noswapfile

let s:search_path_separator = has('win32') ? ';' : ':'
function! AddToPath(...)
    
    " NOTE: Apparently regexp matching doesn't do its job here so I had to
    " take matters into my own hands.
    let paths = {} " As far as I know, vim doesn't have sets
    for path in split($PATH, s:search_path_separator)
        if path !=# '' && !has_key(paths, path)
            let paths[path] = ''
        endif
    endfor

    " Previously the filter used 'val !~# $PATH' but that didn't work
    " for some reason
    let new_components = filter(copy(a:000),
                              \ { idx, val ->
                              \     (val !=# '' && !has_key(paths, val))
                              \ })
    call extend(new_components, [$PATH])
    let $PATH = join(new_components, s:search_path_separator)
endfunction

if has('win32')
    call AddToPath('C:\tools', 'C:\Program Files\Git\bin', '')
else
    call AddToPath('/usr/local/sbin', $HOME . '/bin', '/usr/local/bin')
endif

let s:dot_vim_path = fnamemodify(expand("$MYVIMRC"), ":p:h")

if filereadable(s:dot_vim_path . '/autoload/plug.vim')
    call plug#begin(s:dot_vim_path . '/plugins')

    " Languages
    " Plug 'keith/swift.vim'
    " Plug 'rust-lang/rust.vim'

    " Utilities
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'

    " Git support
    Plug 'tpope/vim-fugitive'

    call plug#end()
endif

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

nnoremap Y y$

" Tab shortcuts
nnoremap <silent> ghe :vnew<CR>
nnoremap <silent> gce :tabnew<CR>
nnoremap <silent> ge  :vnew \| wincmd H<CR>

function! MoveTab(multiplier, count)
    let amount  = a:count ? a:count : 1
    let cur_tab = tabpagenr()
    let n_tabs  = tabpagenr("$")
    let new_place = cur_tab + a:multiplier * amount

    if new_place <= 0
        let amount = cur_tab - 1
    elseif new_place > n_tabs
        let amount = n_tabs - cur_tab
    endif

    if amount != 0
        let cmd = ['tabmove ', '', a:multiplier * amount]

        if a:multiplier > 0
            let cmd[1] = '+'
        endif

        let cmd = join(cmd, "")
        " echo "Moving Tabs " . cmd
        execute cmd
    endif
endfunction

nnoremap <silent> g{ :<C-U>call MoveTab(-1, v:count)<CR>
nnoremap <silent> g} :<C-U>call MoveTab(+1, v:count)<CR>

" I don't know if I really want this...Like, I don't know
" if it inspires joy, ya-know, man??
" nnoremap v <C-V>
" vnoremap v <C-V>

function! ReenterVisual()
    normal! gv
endfunction

" This is probably the greatest thing I've ever made in vim.
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
        execute join([prev_command, " terminal ", a:options, " ++noclose ", s:debugger], "")
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
    call setpos(".", open_pos)
endfunction

" Autocomplete blocks (The <C-O> is so that it doesn't make a new undo)
inoremap          {<CR> {<CR>}<C-O>=k<C-O>o
inoremap <silent> } }<C-O>%<C-O>:call RebalanceCurrentBlock()<CR><C-O>%<C-G>U<Right>

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

cnoremap <C-W> \<\><Left><Left>

" Move selected lines up and down
vnoremap <C-J> :m '>+1<CR>gv=gv
vnoremap <C-K> :m '<-2<CR>gv=gv

" Horizontal scrolling. Only useful when wrap is turned off.
nnoremap <C-J> zl
nnoremap <C-H> zh

" Commands for convenience
command! -bang Q q<bang>
command! -bang Qa qa<bang>
command! -bang QA qa<bang>
command! -bang -complete=file W w<bang> <args>
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
    \ 'm' : '//',
    \ 'mm' : '//',
    \ 'vim' : '"',
    \ 'python' : '#',
    \ 'tex' : '%'
\ }

function! RemoveCommentLeadersNormal(count)
    if has_key(s:comment_leaders, &filetype)
        let leader = substitute(s:comment_leaders[&filetype], '\/', '\\/', 'g')

        let cur_pos = getpos(".")
        let current_line = cur_pos[1]

        " TODO: consider making the removal of the comment leader depend on
        " whether or not the previous line has the leader.
        if getline(current_line) =~ '^\s*' . leader
            let lastline = current_line + (a:count == 0 ? 1 : a:count)
            let command = join([(current_line+1), ",", lastline, 's/^\s*', leader, "\s*//e"], "")
            execute command
        endif

        call setpos(".", cur_pos)
    endif

    execute join(["normal! ", (a:count+1), "J"], "")
endfunction

function! RemoveCommentLeadersVisual() range
    if has_key(s:comment_leaders, &filetype)
        let leader = substitute(s:comment_leaders[&filetype], '\/', '\\/', 'g')

        if getline(a:firstline) =~ '^\s*' . leader
            let command = join([(a:firstline + 1), ",", a:lastline, 's/^\s*', leader, '\s*//e'], "")
            execute command
        endif

        normal! gvJ
        " echo command
    endif
endfunction
vnoremap <silent> J :call RemoveCommentLeadersVisual()<CR>
nnoremap <silent> J :<C-U>call RemoveCommentLeadersNormal(v:count)<CR>

" NOTE: redrawtabline doesn't exist on all vim compiles so I have to check for
" it. Use this function instead so that the check isn't done every time
if exists(":redrawtabline")
    function! RedrawTabLine()
        redrawtabline
    endfunction
else
    function! RedrawTabLine()
    endfunction
endif

augroup EnterAndLeave
    " Enable and disable cursor line in other buffers
    autocmd!
    autocmd     WinEnter * set   cursorline | call RedrawTabLine()
    autocmd     WinLeave * set nocursorline | call RedrawTabLine()
    autocmd  InsertEnter * set nocursorline | call RedrawTabLine()
    autocmd  InsertLeave * set   cursorline | call RedrawTabLine()

    autocmd CmdlineEnter *                    call RedrawTabLine()
    autocmd CmdlineLeave *                    call RedrawTabLine()

    " autocmd CmdlineEnter / call OverrideModeName("Search") | call RedrawTabLine()
    " autocmd CmdlineLeave / call OverrideModeName(0) | call RedrawTabLine()

    " autocmd CmdlineEnter ? call OverrideModeName("Reverse Search") | call RedrawTabLine()
    " autocmd CmdlineLeave ? call OverrideModeName(0) | call RedrawTabLine()

    " I created these but they don't work as intended yet
    " autocmd  VisualEnter *                    call RedrawTabLine()
    " autocmd  VisualLeave *                    call RedrawTabLine()
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
let g:netrw_keepdir = 1

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
    let cur_tab_page = tabpagenr()
    let n_tabs = tabpagenr("$")
    let max_file_name_length = 30

    " NOTE: Repeat is used to pre-allocate space, make sure that this is the
    " correct number of characters, otherwise you'll get an error

    let prefixes = [" ", GetCurrentMode(), " "]
    " %= is the separator between left and right side of tabline
    " %T specifies the end of the last tab
    let suffixes = ["%T%#TabLineFill#%=%#TabLineSel# ", strftime(s:timeformat), " "]

    let num_prefixes = len(prefixes)
    let num_suffixes = len(suffixes)

    let strings_per_tab = 7
    let s = repeat(['EMPTY!!!'], num_prefixes + n_tabs * strings_per_tab + num_suffixes)

    " TODO: Make this a different colour
    for i in range(num_prefixes)
        let s[i] = prefixes[i]
    endfor

    for i in range(num_suffixes)
        let s[i - num_suffixes] = suffixes[i]
    endfor

    " Previously this was initialized to an empty list and I was using
    " extend() to add elements
    " let s = [] " Not sure if a list is faster than a string but there is no stringbuilder in vimscript

    for i in range(n_tabs)
        let n = i + 1
        let bufnum = tabpagebuflist(n)[tabpagewinnr(n) - 1]

        " %<num>T specifies the beginning of a tab
        let s[num_prefixes + i * strings_per_tab + 0] = "%"
        let s[num_prefixes + i * strings_per_tab + 1] = n

        let s[num_prefixes + i * strings_per_tab + 2] = n == cur_tab_page ? "T%#TabLineSel# " : "T%#TabLine# "

        let s[num_prefixes + i * strings_per_tab + 3] = n

        " '-' for non-modifiable buffer, '+' for modified, ':' otherwise
        let modifiable = getbufvar(bufnum, "&modifiable")
        let modified   = getbufvar(bufnum, "&modified")
        let s[num_prefixes + i * strings_per_tab + 4] = !modifiable ?  "- " : modified ? "* " : ": "

        let name = bufname(bufnum)
        let s[num_prefixes + i * strings_per_tab + 5] = name == "" ? "[New file]" : (len(name) >= max_file_name_length ? "<" . name[-max_file_name_length:] : name)

        let s[num_prefixes + i * strings_per_tab + 6] = " "
    endfor

    return join(s, "")
endfunction

" Can type unicode codepoints with C-V u <codepoint> (ex. 2002)
" Maybe put the tabs in the status bar or vice-versa (probably better in the
" tab bar so that information is not duplicated
function! StatusLine() abort
    let winnum = winnr() " tabpagebuflist(n)[tabpagewinnr(n) - 1]
    let bufnum = winbufnr(winnum)
    let name   =  bufname(bufnum)

    let result  = ""

    if bufnum == bufnr("%")
        let result .= " " . GetCurrentMode()
    endif

    " let result .= " " . winnum 
    let result .= " > " . name
    let filetype = getbufvar(bufnum, "&filetype")
    if len(filetype) != 0
        let result .= " " . l:filetype
    endif

    let modifiable = getbufvar(bufnum, "&modifiable")
    let modified   = getbufvar(bufnum, "&modified")
    let result .= !modifiable ? " -" : modified ? " +" : ""

    return result . " "
endfunction

set statusline=%!StatusLine()
set tabline=%!Tabs()

call timer_stopall()
function! RedrawTabLineRepeated(timer)
    " Periodically redraw the tabline so that the current time is correct
    " echo "Redrawing tab line repeated " . strftime('%H:%M:%S')
    call RedrawTabLine()
endfunction
function! RedrawTabLineFirst(timer)
    " The first redraw of the tab line so that it updates on the minute
    " echo "Redrawing tab line first " . strftime('%H:%M:%S')
    call RedrawTabLine()
    call timer_start(1 * 1000 * 60, 'RedrawTabLineRepeated', {'repeat':-1})
endfunction

let s:seconds_until_next_minute = 60 - str2nr(strftime('%S'))
call timer_start(s:seconds_until_next_minute * 1000, 'RedrawTabLineFirst')

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
augroup END

" cterm colours are not correct
hi CustomRed         guifg=#eb4034 guibg=NONE ctermfg=160 ctermbg=NONE gui=none cterm=none
hi CustomYellow      guifg=#d7d7af guibg=NONE ctermfg=187 ctermbg=NONE gui=none cterm=none
hi CustomGreen       guifg=#55bd53 guibg=NONE ctermfg=112 ctermbg=NONE gui=none cterm=none
hi CustomBlue        guifg=#33c0d6 guibg=NONE ctermfg=153 ctermbg=NONE gui=none cterm=none
hi CustomOrange      guifg=#e54f00 guibg=NONE ctermfg=166 ctermbg=NONE gui=none cterm=none
hi CustomDarkBlue    guifg=#5f87ff guibg=NONE ctermfg=69  ctermbg=NONE gui=none cterm=none
hi CustomHotPink     guifg=#d75faf guibg=NONE ctermfg=169 ctermbg=NONE gui=none cterm=none
hi CustomPurple      guifg=#950087 guibg=NONE ctermfg=90  ctermbg=NONE gui=none cterm=none

" ============================================
" Common variables that may be needed by other functions
let g:path_separator = has('win32') ? '\' : '/'

let g:header = ['/*',
            \ '  File: {file_name}',
            \ '  Date: {date}',
            \ '  Creator: {creator}',
            \ '  Notice: (C) Copyright %Y by {copyright_holder}. All rights reserved.',
            \ '*/',
            \ ]

let g:header_sub_options = {
            \    'date_format' : "%d %B %Y",
            \    'creator'     : 'Alexandru Filip',
            \    'copyright_holder' : 'Alexandru Filip'
            \ }

" TODO: Make the headers project specific
function! CreateSourceHeader()
    let file_name = expand('%:t')
    let file_extension = split(file_name, '\.')[1]
    let date = strftime(g:header_sub_options['date_format'])
    let year = strftime("%Y")

    let l:header = []
    for str in g:header

        let start_idx = 0
        while 1
            let option_idx =  match(str, '{[A-Za-z_]\+}', start_idx)

            if option_idx == -1
                break
            endif

            let end_idx = match(str, '}', option_idx)
            let length = end_idx - option_idx - 1

            let key = str[option_idx:end_idx]

            if key == '{file_name}'
                let value = file_name
            elseif key == '{date}'
                let value = date
            elseif has_key(g:header_sub_options, key[1:-2])
                let value = get(g:header_sub_options, key[1:-2])
            else
                let value = 0
                let start_idx = end_idx + 1
            endif

            if value isnot 0
                let str = substitute(str, key, value, 'g')
                let start_idx = option_idx + len(value)
            endif
        endwhile

        let str = strftime(str)
        call add(l:header, str)
    endfor

    call append(0, l:header)

    if file_extension =~ '^[hH]\(pp\|PP\)\?$'
        let modified_filename = substitute(toupper(file_name), '[^A-Z]', '_', 'g')

        let guard = [
                    \ '#ifndef ' . modified_filename,
                    \ '#define ' . modified_filename,
                    \ '',
                    \ '',
                    \ '',
                    \ '#endif',
                    \ ]
        call append(line("$"), guard)

        let pos = getpos("$")
        let pos[1] -= 2
        call setpos(".", pos)
    endif
endfunction

augroup FileHeaders
    autocmd!
    autocmd BufNewFile *.c,*.cpp,*.h,*.hpp call CreateSourceHeader()
augroup END

" = Terminal commands ========================

" Search for a script named "build.bat" moving up from the current path and run it.
" TODO: find out how to compile through vim on windows
let s:compile_script_name = has('win32') ? 'build.bat' : './compile'

function! IsTerm()
    return get(getwininfo(bufwinid(bufnr()))[0], 'terminal', 0)
endfunction

function! IsTermAlive()
    let job = term_getjob(bufnr())
    return job != v:null && job_status(job) != "dead"
endfunction

function! SwitchToOtherPaneOrCreate()
    let start_win = winnr()
    let layout = winlayout()
    if layout[0] == 'leaf'
        " Create new vertical pane and go to left one
        wincmd v
        wincmd l
    elseif layout[0] == 'row'
        " Buffers layed out side by side
        wincmd l
        if winnr() == start_win
            wincmd h
        endif
    elseif layout[0] == 'col'
        " Buffers layed out one on top of the other
        wincmd j
        if winnr() == start_win
            wincmd k
        endif
    endif
endfunction

function! GotoLineFromTerm()
    if IsTerm()
        let line_contents = getline(".")
        let regex = has('win32') ? '[A-Za-z0-9\.:\\]\+([0-9]\+)' : '^[A-Za-z0-9/\-\.]\+:[0-9]\+:'

        if match(line_contents, regex) != -1
            if has('win32')
                let  open_paren = match(line_contents, '(', 0)
                let close_paren = match(line_contents, ')', open_paren)

                let filepath = line_contents[:open_paren-1]
                let line_num = line_contents[open_paren+1:close_paren-1]
                let col_num = 0

            else
                let [filepath, line_num, col_num] = split(line_contents, ":")[:2]
            endif

            let line_num = str2nr(line_num)
            if col_num =~ '^[0-9]\+'
                let col_num = str2nr(col_num)
            else
                let col_num = 0
            endif

            call SwitchToOtherPaneOrCreate()
            " NOTE: We might want to save the current file before switching
            execute "edit " . filepath

            if col_num == 0
                let col_num = indent(line_num) + 1
            endif

            call setpos(".", [0, line_num, col_num, 0])
            normal! zz
        else
            echo join(["Line does not match known error message format (", regex, ")"], "")
        endif
    endif
endfunction

function! DoCommandsInTerm(shell, commands, parent_dir, message)
    " Currently, this assumes you only have one split and uses only the top-most
    " part of the layout as the guide.

    " NOTE: The problem with this is that a terminal in a split that is not
    " right beside the current one will not be reused. This will create a new
    " terminal.

    if !IsTerm()
        call SwitchToOtherPaneOrCreate()
    endif

    let all_commands = a:commands

    if a:parent_dir isnot 0
        let all_commands = join(['cd "', a:parent_dir, '" && ', all_commands], "")
    endif

    if a:message isnot 0
        let all_commands .= ' && echo ' . a:message
    endif

    if IsTermAlive()
        if get(job_info(term_getjob(bufnr())), 'cmd', [''])[0] =~ 'zsh'
            let all_commands = join(["\<Esc>cc", all_commands, "\r\n"], "")
        endif

        call term_sendkeys(bufnr(), all_commands)
    else
        let cmd = join(["terminal++noclose ++curwin", a:shell, all_commands], " ")
        execute cmd
    endif
endfunction

function! SearchAndRun(script_name)
    " NOTE: I'm separating this out because it seems like it would be handy
    " for running tests as well

    let working_dir = has('win32') ? [] : [""]
    call extend(working_dir, split(getcwd(), g:path_separator))

    while len(working_dir) > 0
        let directory_path = join(working_dir, g:path_separator)
        if executable(join([directory_path, g:path_separator, a:script_name], ""))
            " One problem with this is that I can't scroll through the
            " history to see all the errors from the beginning
            let script = a:script_name

            let completed_message = "Compiled Successfully"
            if has('win32')
                let script = 'C:\tools\shell-init.bat && ' . script
                let completed_message = 0
            endif

            call DoCommandsInTerm('++shell', script, directory_path, completed_message)
            return
        endif
        let working_dir = working_dir[:-2] " remove last path element
    endwhile
    echo join(["No file named \"", a:script_name, "\" found"], "")
endfunction

function! SearchAndCompile()
    call SearchAndRun(s:compile_script_name)
endfunction

nnoremap <silent> <leader>g :call GotoLineFromTerm()<CR>
nnoremap <silent> <leader>c :call SearchAndCompile()<CR>

" = Man =================================

if has('win32')
    function! ManEntry(name)
        execute "vertical term ++close man " . a:name
    endfunction
    command! -nargs=1 Man :call ManEntry(<q-args>)
endif

" =======================================

function! RenameFiles()
    " NOTE: Does not work on Windows, yet.
    " Empty lines are allowed
    let lines = filter(getline(1, '$'), {idx, val -> len(val) > 0})
    let file_list = split(system("ls"), '\n')

    if len(lines) != len(file_list)
        echoerr join(["Number of lines in buffer (", len(lines),
                    \ ") does not match number of files in current directory (", 
                    \ len(file_list), ")"], "")
        return
    endif

    let commands = repeat([''], len(file_list))
    for index in range(len(file_list))
        " TODO: replace characters that need escaping with \char
        let commands[index] = join(["mv \"", file_list[index], "\" \"", lines[index], "\""], "")
    endfor

    normal ggdG
    put =commands

    " I would still have to make sure that all of the appropriate characters
    " in the filename, like quotes, are escaped.
    "
    " Start by running :r !ls
    " Change names within the document
    " Run :w !zsh after this (use your shell of choice. Can get this with &shell)
endfunction
command! RenameFiles :call RenameFiles()

" = Projects ==================================

" NOTE: Option idea for project:
"   C/C++ with compile scripts and main
"   Client projects (compile scripts and a folder inside with the actual code)
" TODO: Project files in json format to get
let g:projects_folder = has('win32') ? 'C:\projects' : '~/projects'
function! ProjectsCompletionList(ArgLead, CmdLine, CursorPos)
    if a:ArgLead =~ '^-.\+' || a:ArgLead =~ '^++.\+'
        " TODO: command completion for options
    else
        let result = []
        let arg_match = join(["^", a:ArgLead, ".*"], "")

        for path in split(globpath(g:projects_folder, "*"), "\n")
            if isdirectory(path)
                let folder_name = split(path, g:path_separator)[-1]
                if folder_name =~ arg_match
                    call add(result, folder_name)
                endif
            endif
        endfor

        return result
    endif
endfunction

let s:default_project_file = {
    \ 'header' : g:header,
    \ 'header_sub_options' : g:header_sub_options
\ }

function! GoToProjectOrMake(bang, command_line)
    let path_start = 0
    let options = []

    while path_start < len(a:command_line)
        if match(a:command_line, '++', path_start) == path_start
            let path_start += 2
        elseif match(a:command_line, '-', path_start) == path_start
            let path_start += 1
        else
            break
        endif

        let option_end = match(a:command_line, '[ \t]\|$', path_start)
        let option = a:command_line[path_start:option_end-1]
        call add(options, option)

        let path_start = match(a:command_line, '[^ \t]\|$', option_end)
    endwhile

    let project_name = a:command_line[path_start:]

    if len(project_name) != 0
        execute 'cd ' . g:projects_folder
        if !isdirectory(project_name)
            if filereadable(project_name)
                if a:bang
                    call delete(project_name)
                else
                    echoerr project_name . ' exists and is not a directory. Use Project! to replace it with a new project.'
                    return
                endif
            endif
            echo join(['Created new project called "',  project_name, '"'], "")
            call mkdir(project_name)
        endif

        execute 'cd ' . project_name
        edit .
    else
        echoerr 'No project name specified'
        return
    endif
endfunction
command! -bang -nargs=1 -complete=customlist,ProjectsCompletionList  Project :call GoToProjectOrMake(<bang>0, <q-args>)


" = Search ====================================

function! SearchFolder(searchTerm)
    let searchTerm = a:searchTerm
    let searchTerm = substitute(searchTerm, '\\', '\\\\', 'g')
    let searchTerm = join(['"', substitute(searchTerm, '"', '\"', 'g'), '" .'], "")
    call DoCommandsInTerm('grep -REn', searchTerm, 0, 0)
endfunction
command! -nargs=1 Search :call SearchFolder(<q-args>)

" = RFC =======================================
function! GetRFC(num)
    " NOTE: Does not work on windows unless curl is installed
    if a:num =~ '^[0-9]\+$'
        let num = a:num
        if len(num) < 4
            if num == '0'
                let num = '000'
            else
                let num = repeat('0', 4 - len(num)) . l:num
            endif
        endif

        let rfc_name = join(['rfc', l:num, '.txt'], "")
        let rfc_path = join([g:rfc_download_location, '/', rfc_name], "")

        if filereadable(rfc_path)
            " Do nothing here. Open file after if-else blocks
        elseif executable('curl')
            if !isdirectory(g:rfc_download_location)
                call mkdir(g:rfc_download_location)
            endif
            echo 'Downloading'
            call system(join(['curl https://www.ietf.org/rfc/', rfc_name, " -o '", rfc_path, "'"], ""))
        else
            echoerr 'curl is not installed on this machine'
            return
        endif

        call SwitchToOtherPaneOrCreate()
        execute 'edit ' . rfc_path

    else
        echoerr join(['"', a:num, '" is not a number'], "")
    endif
endfunction
command! -nargs=1 RFC :call GetRFC(<q-args>)

" Can change this in the machine specific vimrc
let g:rfc_download_location = $HOME . '/RFC-downloads'

" Abbreviations in insert mode (should these be commands?
iabbrev <silent> :Now:     <Esc>:let @x = strftime("%X")<CR>"xpa
iabbrev <silent> :Today:   <Esc>:let @x = strftime("%d %b %Y")<CR>"xpa
iabbrev <silent> :Random:  <Esc>:let @x = rand()<CR>"xpa

" =============================================

" From vim wiki to identify the syntax group under the cursor
" nnoremap <F10> :echo "hi<" . synIDattr(           synID(line("."), col("."), 1) , "name") . '> trans<'
"                          \ . synIDattr(           synID(line("."), col("."), 0) , "name") . "> lo<"
"                          \ . synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") . ">"<CR>

let g:OperatorList = {}
let g:OperatorChar = 0
let s:visual_modes = {    'v':'char',    'V':'line', '\<C-V>':'block',
                     \ 'char':'char', 'line':'line',  'block':'block' }
function! s:is_a_visual_mode(mode)
    return has_key(s:visual_modes, a:mode)
endfunction

function! s:do_nothing(...)
endfunction

" This can't be a script-only (s:) function because it needs to be called from
" the command-line.

function! OperGetLine(col)
    let position = getpos(".")
    let result = { 'line':position[2], 'column':0 }

    if a:col != 0
        let result['column'] = len(getline("."))
    endif

    return result
endfunction

function! PerformOperator(visual)
    if g:OperatorChar isnot 0
        call get(g:OperatorList, g:OperatorChar, funcref('s:do_nothing'))['handler'](a:visual)
        let g:OperatorChar = 0
    endif
endfunction

function! MakeOperator(char, func)
    let func_holder = { 'func' : a:func }
    function! func_holder.handler(visual) dict
        let mode = get(s:visual_modes, a:visual, 0)

        if a:visual != 'char' && mode isnot 0
            let [start_mark, end_mark] = ["'<", "'>"]
        else
            let [start_mark, end_mark] = ["'[", "']"]
            let mode = 'normal'
        endif

        let [start_line, start_column] = getpos(start_mark)[1:2]
        let [  end_line,   end_column] = getpos(  end_mark)[1:2]
        " echoerr start_line . " " . end_line
        let start = { 'line':start_line, 'column':start_column }
        let   end = { 'line':  end_line, 'column':  end_column }
        call self['func'](mode, start, end)
    endfunction

    let char = a:char[0]
    let g:OperatorList[char] = func_holder
    " let escaped_char = substitute(char, '\', '\\\\', 'g')

    let normal_command = "nnoremap <silent> " . char .  " :let g:OperatorChar = '" . char . "'<CR>:set operatorfunc=PerformOperator<CR>g@"
    let oper_func_get  = "OperatorList['" . char . "']['handler']"
    let visual_command = "vnoremap <silent> " . char .  " :<C-U>call " . oper_func_get . "(visualmode())<CR>"

    silent execute normal_command
    silent execute visual_command
endfunction

" function! Backslash(mode, start, end)
"     echo "Backslash " a:mode a:start a:end
" endfunction

" nnoremap <silent> \\ :call Backslash("normal", OperGetLine(0), OperGetLine(-1))<CR>
" nnoremap <silent> \/ :call Backslash("normal", OperGetLine(0), OperGetLine(-1))<CR>
" call MakeOperator('\', funcref('Backslash'))

" function! OpenBracket(mode, start, end)
"     echo "Open bracket " a:mode a:start a:end
" endfunction

" NOTE: So far I haven't been able to remap [[ and similar keymaps. I'm not sure
" why.
" nnoremap <silent> [[ :call OpenBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
" nnoremap <silent> [] :call OpenBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
" call MakeOperator('[', funcref('OpenBracket'))

" function! CloseBracket(mode, start, end)
"     echo "Close bracket" a:mode a:start a:end
" endfunction

" nnoremap <silent> ]] :call CloseBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
" nnoremap <silent> ][ :call CloseBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
" call MakeOperator(']', funcref('CloseBracket'))


" set indentexpr=CustomIndent()
" function! CustomIndent()
"     let line_num = line(".")
"     let prev_lnum = line_num
"     let prev_line = ''
"     let prev_indent = 0
"     
"     while 1
"         let prev_lnum -= 1
" 
"         if prev_lnum <= 1
"             break
"         endif
" 
"         let prev_line = getline(prev_lnum)
"         if prev_line != ''
"             break
"         endif
"     endwhile
" 
"     let prev_indent = indent(prev_lnum)
" 
"     return cindent(line_num)
" endfunction

" For machine specific additions changes
let s:local_vimrc_path = join([$HOME, '.local', 'vimrc'], g:path_separator)
if filereadable(s:local_vimrc_path)
    execute "source " . s:local_vimrc_path
endif

" Re-source gvimrc when vimrc is reloaded
let s:gvim_path = join([s:dot_vim_path, 'gvimrc'], g:path_separator)
if has('gui') && filereadable(s:gvim_path)
    execute "source " . s:gvim_path
endif