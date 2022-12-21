vim9script
syntax on

# Autoreload file
set autoread # automatically reload file when changed on disk

# Persistent Undo
set undofile                  # Save undos after file closes
set undolevels=1000           # How many undos
set undoreload=10000          # number of lines to save for undo
set undodir=$HOME/.local/vim-undos # where to save undo histories

const undo_dir = expand("~/.local/vim-undos/")
if !isdirectory(undo_dir)
    mkdir(undo_dir)
endif

# Miscellaneous
set splitright        # Vertical split goes right, not left
set showcmd           # Show the current command in operator pending mode
set cursorline        # Make the cursor line a visible color
set noshowmode        # Don't show -- INSERT --
set mouse=a           # Allow mouse input
set sidescroll=1      # Number of columns to scroll left and right
set backspace=indent  # allow backspacing only over automatic indenting (:help 'backspace')
set showtabline=2     # 0 = never show tabline, 1 = when more than one tab, 2 = always
set laststatus=0      # Whether or not to show the status line. Values same as showtabline
set clipboard=unnamed # Use system clipboard
set wildmenu          # Display a menu of all completions for commands when pressing tab

set wrap linebreak breakindent # Wrap long lines
set breakindentopt=shift:0,min:20
set formatoptions+=n 
set virtualedit=block # Visual block mode is not limited to the character locations

set nofixendofline    # Don't insert an end of line at the end of the file
set noeol             # Give it a mean look so it understands

# Leader mappings
g:mapleader = " "

if !has('win32') && executable('/bin/zsh')
    set shell=/bin/zsh # Shell to launch in terminal
endif

# Indenting
set tabstop=4 shiftwidth=0 softtabstop=-1 expandtab
set cindent cinoptions=l1,=0,:4,(0,{0,+2,w1,W4,t0
set shortmess=filnxtToOIs

# set viminfo+=n$VIMRUNTIME/info # Out of sight, out of mind
set viminfo=

set display=lastline # For writing prose
set noswapfile

def MakeDict(keys: list<string>): dict<string>
    final result: dict<string> = {}
    for key in keys
        result[key] = ''
    endfor
    return result
enddef

const search_path_separator = has('win32') ? ';' : ':'

def AddToPath(...args: list<string>)
    # As far as I know, vim doesn't have sets
    const paths = MakeDict(filter(split($PATH, search_path_separator), (index: number, path: string): bool => {
        return path !=# ''
    }))

    # Previously the filter used 'val !~# $PATH' but that didn't work
    # for some reason
    final new_components = filter(copy(args), (idx: number, val: any): bool => { 
        return (val !=# '' && !has_key(paths, val))
    })

    extend(new_components, [$PATH])
    $PATH = join(new_components, search_path_separator)
enddef

if has('win32')
    AddToPath('C:\tools', 'C:\Program Files\Git\bin', '')
else
    AddToPath('/usr/local/sbin', $HOME .. '/bin', '/usr/local/bin')
endif

const path_separator = has('win32') ? '\' : '/'
const dot_vim_path = fnamemodify(expand("$MYVIMRC"), ":p:h")

# For machine specific additions changes
const local_vimrc_path = join([$HOME, '.local', 'vimrc'], path_separator)
if filereadable(local_vimrc_path)
    execute "source " .. local_vimrc_path
endif

if filereadable(dot_vim_path .. '/autoload/plug.vim')
    plug#begin(dot_vim_path .. '/plugins')

    # Languages
    # Plug 'keith/swift.vim'
    # Plug 'rust-lang/rust.vim'

    # Utilities
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'

    # Git support
    Plug 'tpope/vim-fugitive'

    if exists('*g:LocalVimRCPlugins')
        g:LocalVimRCPlugins()
    endif


    plug#end()
endif

filetype plugin on
colorscheme custom

# TODO: Install ripgrep and fzf here

# Diff files
nnoremap <leader>d :if &diff \| diffoff \| else \| diffthis \| endif<CR>

# Git merge conflicts
nnoremap <leader>gd :vert Gdiffsplit!<CR>
nnoremap <leader>gh :diffget //2<CR>
nnoremap <leader>gl :diffget //3<CR>

# Make help window show up on right, not above
augroup MiscFile
    autocmd!
    autocmd FileType help wincmd L
    # Reload _vimrc on write
    # Neither of these work
    autocmd BufWritePost $MYVIMRC  source $MYVIMRC
    autocmd BufWritePost $MYGVIMRC source $MYGVIMRC
augroup END

augroup WrapLines
    autocmd!
    autocmd FileType {txt,org,tex} setlocal wrap linebreak nolist
augroup END

nnoremap Y y$

# Tab shortcuts
nnoremap <silent> ghe :vnew<CR>
nnoremap <silent> gce :tabnew<CR>
nnoremap <silent> ge  :vnew \| wincmd H<CR>

def g:MoveTab(multiplier: number, count: number)
    const cur_tab    = tabpagenr()
    const n_tabs     = tabpagenr("$")
    const amount     = multiplier * max([count, 1])
    const new_place  = min([max([cur_tab + amount, 1]), n_tabs])

    execute 'tabmove ' .. (new_place < cur_tab ? new_place - 1 : new_place)
enddef

nnoremap <silent> g{ :<C-U>call g:MoveTab(-1, v:count)<CR>
nnoremap <silent> g} :<C-U>call g:MoveTab(+1, v:count)<CR>

# I don't know if I really want this...Like, I don't know
# if it inspires joy, ya-know, man??
# nnoremap v <C-V>
# vnoremap v <C-V>

def g:ReenterVisual()
    normal! gv
enddef

# This is probably the greatest thing I've ever made in vim.
def g:GotoBeginningOfLine()
    if indent(".") + 1 == col(".")
        normal! 0
    else
        normal! ^
    endif
enddef

nnoremap <silent> 0 :<C-U>call GotoBeginningOfLine()<CR>
nnoremap <silent> - $

vnoremap <silent> 0 :<C-U>ReenterVisual() \| GotoBeginningOfLine()<CR>
vnoremap <silent> - $

onoremap <silent> 0 :<C-U>GotoBeginningOfLine()<CR>
onoremap <silent> - $

# Some terminal shortcuts
nnoremap <silent> ght :vertical terminal<CR>
nnoremap <silent> gct :tabnew \| terminal ++curwin<CR>

if !has('win32')
    # Debugger
    const debugger = "lldb"
    def g:LaunchDebugger(vertical: bool, options: string)
        const prev_command = vertical ? "vertical" : "tabnew \|"
        execute join([prev_command, "terminal", options, "++noclose", debugger], " ")
    enddef
    nnoremap <silent> ghd :LaunchDebugger(1, "")<CR>
    nnoremap <silent> gcd :LaunchDebugger(0, "++curwin")<CR>

    # Htop
    nnoremap <silent> ghh :vertical terminal htop<CR>
    nnoremap <silent> gch :tabnew \| terminal ++curwin htop<CR>
endif

# Enter normal mode without getting emacs pinky
tnoremap <C-w>[ <C-\><C-n>
tnoremap <C-w><C-[> <C-\><C-n>

def g:RebalanceCurrentBlock()
    final open_pos = getpos(".")
    const indent_before = indent(".")

    normal! =%

    open_pos[2] += indent(".") - indent_before
    setpos(".", open_pos)
enddef

# Autocomplete blocks (The <C-O> is so that it doesn't make a new undo)
# inoremap          {<CR> {<CR>}<C-O>=k<C-O>o
# inoremap <silent> } }<C-O>%<C-O>:call g:RebalanceCurrentBlock()<CR><C-O>%<C-G>U<Right>

# Useless Keys
nnoremap <CR>    <nop>
nnoremap <BS>    <nop>
nnoremap <Del>   <nop>
nnoremap <Space> <nop>

# Who needs Ex-mode these days?
nnoremap Q <nop>

# NOTE: cnoremap seems broken
# Terminal movement in command line mode
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
cnoremap <C-a> <C-b>
# cnoremap <C-e> <C-e> # already exists
cnoremap <c-d> <Del>

cnoremap <c-w> \<\><Left><Left>


# Search selected text
var visual_search_len = 0
var visual_search_reversed = false

def g:VisualSearchNext(reverse: bool)
    exec 'normal! ' .. (xor(visual_search_reversed ? 1 : 0, reverse ? 1 : 0) != 0 ? 'N' : 'n') .. 'v' .. (visual_search_len > 0 ? visual_search_len .. 'l' : '')
enddef

# Search what is selected with *, #, n and N
def g:ReselectSearched(reverse: bool)
    final first_pos = getpos("'<")
    final last_pos = getpos("'>")

    if first_pos[1] == last_pos[1]
        const line = getline(first_pos[1])
        const searched = line[first_pos[2] - 1 : last_pos[2] - 1]
        visual_search_len = len(searched) - 1
        visual_search_reversed = reverse

        const match_id = '[A-Za-z0-9_]'
        const prefix = line[first_pos[2] - 1] =~ match_id && (first_pos[2] == 1         || line[first_pos[2] - 2] !~ match_id) ?  '\<' : ''
        const suffix = line[ last_pos[2] - 1] =~ match_id && ( last_pos[2] == len(line) || line[ last_pos[2]]     !~ match_id) ?  '\>' : ''

        @/ = prefix .. searched .. suffix
        g:VisualSearchNext(false)
    else
        normal! gv
    endif
enddef

vnoremap <silent> * :<C-U>call g:ReselectSearched(v:false)<CR>
vnoremap <silent> n :<C-U>call g:VisualSearchNext(v:false)<CR>
vnoremap <silent> # :<C-U>call g:ReselectSearched(v:true)<CR>
vnoremap <silent> N :<C-U>call g:VisualSearchNext(v:true)<CR>

# Move selected lines up and down
vnoremap <C-J> :m '>+1<CR>gv=gv
vnoremap <C-K> :m '<-2<CR>gv=gv

# Horizontal scrolling. Only useful when wrap is turned off.
nnoremap <C-J> zl
nnoremap <C-H> zh

# Commands for convenience
command! -bang Q q<bang>
command! -bang Qa qa<bang>
command! -bang QA qa<bang>
command! -bang -nargs=? -complete=file W w<bang> <args>
command! -bang -nargs=? -complete=file E e<bang> <args>

def g:ToggleLineNumbers()
    set norelativenumber!
    set nonumber!
enddef
nnoremap <leader>n :call g:ToggleLineNumbers()<CR>

const comment_leaders = {
    'c': '//',
    'cpp': '//',
    'm': '//',
    'mm': '//',
    'vim': '#',
    'python': '#',
    'tex': '%'
}

def RemoveLeadingComments(first_line: number, LastLine: func: number)
    # TODO: consider making the removal of the comment leader depend on
    # whether or not the previous line has the leader.
    const leader = substitute(comment_leaders[&filetype], '\/', '\\/', 'g')
    if getline(first_line) =~ '^\s*' .. leader
        const command = ':' .. join([(first_line + 1), ",", LastLine(), 's/^\s*', leader, "\s*//e"], "")
        execute command
    endif
enddef

def g:RemoveCommentLeadersNormal(count: number)
    if has_key(comment_leaders, &filetype)
        const cur_pos = getpos(".")
        const current_line = cur_pos[1]
        RemoveLeadingComments(current_line, () => current_line + (count == 0 ? 1 : count))
        setpos(".", cur_pos)
    endif

    execute join(["normal! ", (count + 1), "J"], "")
enddef

def g:RemoveCommentLeadersVisual()
    if has_key(comment_leaders, &filetype)
        RemoveLeadingComments(getpos("'<")[1], () => getpos("'>")[1])
        normal! gvJ
    endif
enddef

vnoremap <silent> J :<C-U>call g:RemoveCommentLeadersVisual()<CR>
nnoremap <silent> J :call g:RemoveCommentLeadersNormal(v:count)<CR>

# NOTE: redrawtabline doesn't exist on all vim compiles so I have to check for
# it. Use this function instead so that the check isn't done every time
if exists(":redrawtabline") != 0
    def g:RedrawTabLine()
        redrawtabline
    enddef
else
    def g:RedrawTabLine()
    enddef
endif

augroup EnterAndLeave
    # Enable and disable cursor line in other buffers
    autocmd!
    autocmd     WinEnter * set   cursorline | g:RedrawTabLine()
    autocmd     WinLeave * set nocursorline | g:RedrawTabLine()
    autocmd  InsertEnter * set nocursorline | g:RedrawTabLine()
    autocmd  InsertLeave * set   cursorline | g:RedrawTabLine()

    autocmd CmdlineEnter *                    g:RedrawTabLine()
    autocmd CmdlineLeave *                    g:RedrawTabLine()

    # autocmd CmdlineEnter / OverrideModeName("Search") | g:RedrawTabLine()
    # autocmd CmdlineLeave / OverrideModeName(0) | g:RedrawTabLine()

    # autocmd CmdlineEnter ? OverrideModeName("Reverse Search") | g:RedrawTabLine()
    # autocmd CmdlineLeave ? OverrideModeName(0) | g:RedrawTabLine()

    # I created these but they don't work as intended yet
    # autocmd  VisualEnter *                    g:RedrawTabLine()
    # autocmd  VisualLeave *                    g:RedrawTabLine()
augroup END

# =============================================
# Style changes

# Change cursor shape in different mode (macOS default terminal)
# For all cursor shapes visit
# http://vim.wikia.com/wiki/Change_cursor_shape_in_different_modes
#                 Blink   Static
#         block ¦   1   ¦   2   ¦
#     underline ¦   3   ¦   4   ¦
# vertical line ¦   5   ¦   6   ¦

&t_SI ..= "\e[6 q" # Insert mode
&t_SR ..= "\e[4 q" # Replace mode
&t_EI ..= "\e[2 q" # Normal mode

# Directory tree listing options
g:netrw_liststyle = 1
g:netrw_banner = 0
g:netrw_keepdir = 1

# Docs: http://vimhelp.appspot.com/eval.txt.html
set fillchars=stlnc:\|,vert:\|,fold:.,diff:.

var mode_name_override = null_string
def g:OverrideModeName(name: string)
    mode_name_override = name
enddef

const current_mode = {
    'n':  'Normal',
    'i':  'Insert',
    'v':  'Visual',
    'V':  'Visual Line',
    '': 'Visual Block',
    'R':  'Replace',
    'c':  'Command Line',
    't':  'Terminal'
}

def g:GetCurrentMode(): string 
    # if mode_name_override isnot 0
    #     return mode_name_override
    # else

    return get(current_mode, mode(), mode())

    # endif
enddef

# Hours (24-hour clock) followed by minutes
const timeformat = has('win32') ? '%H:%M' : '%k:%M'

# Custom tabs
def g:Tabs(): string
    # NOTE: getbufinfo() gets all variables of all buffers
    # Colours
    const cur_tab_page = tabpagenr()
    const n_tabs = tabpagenr("$")
    const max_file_name_length = 30

    # NOTE: Repeat is used to pre-allocate space, make sure that this is the
    # correct number of characters, otherwise you'll get an error

    const prefixes = [" ", g:GetCurrentMode(), " "]
    # %= is the separator between left and right side of tabline
    # %T specifies the end of the last tab
    const suffixes = ["%T%#TabLineFill#%=%#TabLineSel# ", strftime(timeformat), " "]

    const num_prefixes = len(prefixes)
    const num_suffixes = len(suffixes)

    const strings_per_tab = 7
    final s = repeat(['EMPTY!!!'], num_prefixes + n_tabs * strings_per_tab + num_suffixes)

    # TODO: Make this a different colour
    for i in range(num_prefixes)
        s[i] = prefixes[i]
    endfor

    for i in range(num_suffixes)
        s[i - num_suffixes] = suffixes[i]
    endfor

    for i in range(n_tabs)
        const n = i + 1
        const bufnum = tabpagebuflist(n)[tabpagewinnr(n) - 1]

        # %<num>T specifies the beginning of a tab
        s[num_prefixes + i * strings_per_tab + 0] = "%"
        s[num_prefixes + i * strings_per_tab + 1] = string(n)

        s[num_prefixes + i * strings_per_tab + 2] = n == cur_tab_page ? "T%#TabLineSel# " : "T%#TabLine# "

        s[num_prefixes + i * strings_per_tab + 3] = string(n)

        # '-' for non-modifiable buffer, '+' for modified, ':' otherwise
        const modifiable = bufnum->getbufvar("&modifiable")
        const modified   = bufnum->getbufvar("&modified")
        s[num_prefixes + i * strings_per_tab + 4] = !modifiable ?  "- " : modified ? "* " : ": "

        const name = bufnum->bufname()
        s[num_prefixes + i * strings_per_tab + 5] = name == "" ? "[New file]" : (len(name) >= max_file_name_length ? "<" .. name[-max_file_name_length : ] : name)

        s[num_prefixes + i * strings_per_tab + 6] = " "
    endfor

    return s->join("")
enddef

# Can type unicode codepoints with C-V u <codepoint> (ex. 2002)
# Maybe put the tabs in the status bar or vice-versa (probably better in the
# tab bar so that information is not duplicated
def g:StatusLine(): string
    const winnum = winnr() # tabpagebuflist(n)[tabpagewinnr(n) - 1]
    const bufnum = winbufnr(winnum)
    const name   =  bufname(bufnum)

    var   result = ""

    if bufnum == bufnr("%")
        result ..= " " .. g:GetCurrentMode()
    endif

    # result ..= " " .. winnum 
    result ..= " > " .. name
    const filetype = getbufvar(bufnum, "&filetype")
    if len(filetype) != 0
        result ..= " " .. filetype
    endif

    const modifiable = getbufvar(bufnum, "&modifiable")
    const modified   = getbufvar(bufnum, "&modified")
    result ..= !modifiable ? " -" : modified ? " +" : ""

    return result .. " "
enddef

set statusline=%!StatusLine()
set tabline=%!Tabs()

timer_stopall()
def g:RedrawTabLineRepeated(timer: any)
    # Periodically redraw the tabline so that the current time is correct
    # echo "Redrawing tab line repeated " .. strftime('%H:%M:%S')
    g:RedrawTabLine()
enddef

def g:RedrawTabLineFirst(timer: any)
    # The first redraw of the tab line so that it updates on the minute
    # echo "Redrawing tab line first " .. strftime('%H:%M:%S')
    g:RedrawTabLine()
    timer_start(1 * 1000 * 60, g:RedrawTabLineRepeated, { 'repeat': -1 })
enddef

timer_start((60 - str2nr(strftime('%S'))) * 1000, g:RedrawTabLineFirst)

# ============================================
# Color Additions
# Highlighting in comments

# NOTE: Reloading causes tests above to stop working, just use :e to reload
# the file
augroup my_todo
    autocmd!
    autocmd Syntax *
            \   syn keyword CustomYellow     containedin=[a-zA-Z]*CommentL\? TODO OPTIMIZE HACK
            \ | syn keyword CustomGreen      containedin=[a-zA-Z]*CommentL\? NOTE INCOMPLETE
            \ | syn keyword CustomRed        containedin=[a-zA-Z]*CommentL\? XXX FIX FIXME BUG IMPORTANT
            \ | syn keyword CustomBlue       containedin=[a-zA-Z]*CommentL\? REVIEW SIMPLIFY
augroup END

# cterm colours are not correct
hi CustomRed         guifg=#eb4034 guibg=NONE ctermfg=160 ctermbg=NONE gui=none cterm=none
hi CustomYellow      guifg=#d7d7af guibg=NONE ctermfg=187 ctermbg=NONE gui=none cterm=none
hi CustomGreen       guifg=#55bd53 guibg=NONE ctermfg=112 ctermbg=NONE gui=none cterm=none
hi CustomBlue        guifg=#33c0d6 guibg=NONE ctermfg=153 ctermbg=NONE gui=none cterm=none
hi CustomOrange      guifg=#e54f00 guibg=NONE ctermfg=166 ctermbg=NONE gui=none cterm=none
hi CustomDarkBlue    guifg=#5f87ff guibg=NONE ctermfg=69  ctermbg=NONE gui=none cterm=none
hi CustomHotPink     guifg=#d75faf guibg=NONE ctermfg=169 ctermbg=NONE gui=none cterm=none
hi CustomPurple      guifg=#950087 guibg=NONE ctermfg=90  ctermbg=NONE gui=none cterm=none

# ============================================
# Common variables that may be needed by other functions
const header = [
    '/*',
    '  File: {file_name}',
    '  Date: {date}',
    '  Creator: {creator}',
    '  Notice: (C) Copyright %Y by {copyright_holder}. All rights reserved.',
    '*/',
]

const header_sub_options = {
    "date_format":      "%d %B %Y",
    "creator":          "Alexandru Filip",
    "copyright_holder": "Alexandru Filip",
}

# TODO: Make the headers project specific
def g:CreateSourceHeader()
    const file_name = expand('%:t')
    const file_extension = split(file_name, '\.')[1]
    const date = strftime(header_sub_options['date_format'])
    const year = strftime("%Y")

    final header_lines = []
    for str in header
        var var_str   = str
        var start_idx = 0

        while 1
            const option_idx =  match(var_str, '{[A-Za-z_]\+}', start_idx)

            if option_idx == -1
                break
            endif

            const end_idx = match(var_str, '}', option_idx)
            const length = end_idx - option_idx - 1

            const key = var_str[option_idx : end_idx]

            var value = null_string
            if key == '{file_name}'
                value = file_name
            elseif key == '{date}'
                value = date
            elseif has_key(header_sub_options, key[1 : -2])
                value = get(header_sub_options, key[1 : -2])
            else
                start_idx = end_idx + 1
            endif

            if value isnot null_string
                var_str = substitute(var_str, key, value, 'g')
                start_idx = option_idx + len(value)
            endif
        endwhile

        var_str = strftime(var_str)
        add(header_lines, var_str)
    endfor

    append(0, header_lines)

    if file_extension =~ '^[hH]\(pp\|PP\)\?$'
        const modified_filename = substitute(toupper(file_name), '[^A-Z]', '_', 'g')

        const guard = [
                    '#ifndef ' .. modified_filename,
                    '#define ' .. modified_filename,
                    '',
                    '',
                    '',
                    '#endif',
                    ]
        append(line("$"), guard)

        final pos = getpos("$")
        pos[1] -= 2
        setpos(".", pos)
    endif
enddef

augroup FileHeaders
    autocmd!
    autocmd BufNewFile *.c,*.cpp,*.h,*.hpp call g:CreateSourceHeader()
augroup END

# = Terminal commands ========================

# Search for a script named "build.bat" moving up from the current path and run it.
# TODO: find out how to compile through vim on windows
const compile_script_name = has('win32') ? 'build.bat' : './compile'

def IsTerm(): bool
    return get(getwininfo(bufwinid(bufnr()))[0], 'terminal', 0) != 0
enddef

def IsTermAlive(): bool
    const job = bufnr()->term_getjob()
    return type(job) != type(v:none) && job->job_status() != "dead"
enddef

def SwitchToOtherPaneOrCreate()
    const start_win = winnr()
    const layout = winlayout()
    if layout[0] == 'leaf'
        # Create new vertical pane and go to left one
        wincmd v
        wincmd l
    elseif layout[0] == 'row'
        # Buffers layed out side by side
        wincmd l
        if winnr() == start_win
            wincmd h
        endif
    elseif layout[0] == 'col'
        # Buffers layed out one on top of the other
        wincmd j
        if winnr() == start_win
            wincmd k
        endif
    endif
enddef

def g:GotoLineFromTerm()
    if IsTerm()
        const line_contents = getline(".")
        const regex = has('win32') ? '[A-Za-z0-9\.:\\]\+([0-9]\+)' : '^[A-Za-z0-9/\-\.]\+:[0-9]\+:'

        if match(line_contents, regex) != -1
            var filepath: string
            var line_num: number
            var col_num: number
            if has('win32')
                const  open_paren = match(line_contents, '(', 0)
                const close_paren = match(line_contents, ')', open_paren)

                filepath = line_contents[ : open_paren-1]
                line_num = line_contents[open_paren + 1 : close_paren - 1]
                col_num = 0

            else
                const [filepath_str, line_num_str, col_num_str] = split(line_contents, ":")[ : 2]
                filepath = filepath_str
                line_num = str2nr(line_num_str)
                col_num  = str2nr(col_num_str)
            endif

            SwitchToOtherPaneOrCreate()
            # NOTE: We might want to save the current file before switching
            execute "edit " .. filepath

            if col_num == 0
                col_num = indent(line_num) + 1
            endif

            setpos(".", [0, line_num, col_num, 0])
            normal! zz
        else
            echo ["Line does not match known error message format (", regex, ")"]->join("")
        endif
    endif
enddef

def DoCommandsInTerm(shell: string, commands: string, parent_dir: string, message: string)
    # Currently, this assumes you only have one split and uses only the top-most
    # part of the layout as the guide.

    # NOTE: The problem with this is that a terminal in a split that is not
    # right beside the current one will not be reused. This will create a new
    # terminal.

    if !IsTerm()
        SwitchToOtherPaneOrCreate()
    endif

    var all_commands = commands

    if parent_dir isnot null_string
        all_commands = ['cd "', parent_dir, '" && ', all_commands]->join("")
    endif

    if message isnot null_string
        all_commands ..= ' && echo ' .. message
    endif

    if IsTermAlive()
        if get(job_info(term_getjob(bufnr())), 'cmd', [''])[0] =~ 'zsh'
            all_commands = ["\<Esc>cc", all_commands, "\r\n"]->join("")
        endif

        term_sendkeys(bufnr(), all_commands)
    else
        const cmd = ["terminal ++noclose ++curwin", shell, all_commands]->join(" ")
        execute cmd
    endif
enddef

def SearchAndRun(script_name: string)
    # NOTE: I'm separating this out because it seems like it would be handy
    # for running tests as well

    var working_dir = has('win32') ? [] : [""]
    extend(working_dir, split(getcwd(), path_separator))

    while len(working_dir) > 0
        const directory_path = working_dir->join(path_separator)
        if executable(join([directory_path, path_separator, script_name], ""))
            # One problem with this is that I can't scroll through the
            # history to see all the errors from the beginning
            const script = script_name
            const completed_message = "Completed Successfully"

            if has('win32')
                script = 'C:\tools\shell-init.bat && ' .. script
                completed_message = null_string
            endif

            DoCommandsInTerm('++shell', script, directory_path, completed_message)
            return
        endif
        working_dir = working_dir[ : -2] # remove last path element
    endwhile
    echo join(["No file named \"", script_name, "\" found"], "")
enddef

def g:SearchAndCompile()
    SearchAndRun(compile_script_name)
enddef

nnoremap <silent> <leader>g :call g:GotoLineFromTerm()<CR>
nnoremap <silent> <leader>c :call g:SearchAndCompile()<CR>

# = Man =================================

if has('win32')
    def ManEntry(name: string)
        execute "vertical term ++close man " .. name
    enddef
    command! -nargs=1 Man :ManEntry(<q-args>)
endif

# =======================================

def g:RenameFiles()
    # NOTE: Does not work on Windows, yet.
    # Empty lines are allowed
    const lines = filter(getline(1, '$'), (idx: number, val: string) => {
        return len(val) > 0
    })

    const file_list = split(system("ls"), '\n')

    if len(lines) != len(file_list)
        echoerr join(["Number of lines in buffer (", len(lines),
                    ") does not match number of files in current directory (", 
                    len(file_list), ")"], "")
        return
    endif

    final commands = repeat([''], len(file_list))
    for index in range(len(file_list))
        # TODO: replace characters that need escaping with \char
        commands[index] = join(["mv \"", file_list[index], "\" \"", lines[index], "\""], "")
    endfor

    normal ggdG
    put =commands

    # I would still have to make sure that all of the appropriate characters
    # in the filename, like quotes, are escaped.
    #
    # Start by running :r !ls
    # Change names within the document
    # Run :w !zsh after this (use your shell of choice. Can get this with &shell)
enddef
command! RenameFiles :call g:RenameFiles()

# = Projects ==================================

# NOTE: Option idea for project:
#   C/C++ with compile scripts and main
#   Client projects (compile scripts and a folder inside with the actual code)
# TODO: Project files in json format to get
const projects_folder = has('win32') ? 'C:\projects' : '~/projects'
def ProjectsCompletionList(ArgLead: string, CmdLine: string, CursorPos: number): list<string>
    if ArgLead =~ '^-.\+' || ArgLead =~ '^++.\+'
        # TODO: command completion for options
        return []
    else
        final result = []
        const arg_match = join(["^", ArgLead, ".*"], "")

        for path in split(globpath(projects_folder, "*"), "\n")
            if isdirectory(path)
                const folder_name = split(path, path_separator)[-1]
                if folder_name =~ arg_match
                    add(result, folder_name)
                endif
            endif
        endfor

        return result
    endif
enddef

const default_project_file = {
    'header': header,
    'header_sub_options': header_sub_options,
    'build_command': compile_script_name
}

def g:GoToProjectOrMake(bang: bool, command_line: string)
    var path_start = 0
    final options = []

    while path_start < len(command_line)
        if match(command_line, '++', path_start) == path_start
            path_start += 2
        elseif match(command_line, '-', path_start) == path_start
            path_start += 1
        else
            break
        endif

        const option_end = match(command_line, '[ \t]\|$', path_start)
        const option = command_line[path_start : option_end - 1]
        add(options, option)

        path_start = match(command_line, '[^ \t]\|$', option_end)
    endwhile
    const project_name = command_line[path_start : ]

    if len(project_name) != 0
        execute 'cd ' .. projects_folder
        if !isdirectory(project_name)
            if filereadable(project_name)
                if bang
                    delete(project_name)
                else
                    echoerr project_name .. ' exists and is not a directory. Use Project! to replace it with a new project.'
                    return
                endif
            endif
            echo join(['Created new project called "',  project_name, '"'], "")
            mkdir(project_name)
        endif

        execute 'cd ' .. project_name
        edit .
    else
        echoerr 'No project name specified'
        return
    endif
enddef
command! -bang -nargs=1 -complete=customlist,ProjectsCompletionList  Project :call g:GoToProjectOrMake(<bang>false, <q-args>)


# = Search ====================================

def g:SearchFolder(searchTerm: string)
    var localSearchTerm = substitute(searchTerm, '\\', '\\\\', 'g')
    localSearchTerm = join(['"', substitute(searchTerm, '"', '\"', 'g'), '" .'], "")
    DoCommandsInTerm('grep -REn', localSearchTerm, null_string, null_string)
enddef
command! -nargs=1 Search :call g:SearchFolder(<q-args>)

# = RFC =======================================
def GetRFC(num: number)
    # NOTE: Does not work on windows unless curl is installed
    const numString = num == 0 ? '000' : printf("%04d", num)

    const rfc_name = join(['rfc', numString, '.txt'], "")
    const rfc_path = join([rfc_download_location, '/', rfc_name], "")

    if filereadable(rfc_path)
        # Do nothing here. Open file after if-else blocks
    elseif executable('curl')
        if !isdirectory(rfc_download_location)
            mkdir(rfc_download_location)
        endif
        echo 'Downloading'
        system(join(['curl https://www.ietf.org/rfc/', rfc_name, " -o '", rfc_path, "'"], ""))
    else
        echoerr 'curl is not installed on this machine'
        return
    endif

    SwitchToOtherPaneOrCreate()
    execute 'edit ' .. rfc_path
enddef
command! -nargs=1 RFC :GetRFC(<q-args>)

# Can change this in the machine specific vimrc
const rfc_download_location = $HOME .. '/RFC-downloads'

# Abbreviations in insert mode. Should these be commands?
iabbrev :Now:    <Esc>:let @x = strftime("%X")<CR>"xpa
iabbrev :Today:  <Esc>:let @x = strftime("%d %b %Y")<CR>"xpa
iabbrev :Random: <Esc>:let @x = rand()<CR>"xpa

# =============================================

# From vim wiki to identify the syntax group under the cursor
# nnoremap <F10> :echo "hi<" .. synIDattr(           synID(line("."), col("."), 1) , "name") .. '> trans<'
#                          \ .. synIDattr(           synID(line("."), col("."), 0) , "name") .. "> lo<"
#                          \ .. synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") .. ">"<CR>

# var OperatorList = {}
# var OperatorChar = 0
# var visual_modes = {    'v':'char',    'V':'line', '\<C-V>':'block',
#                      'char':'char', 'line':'line',  'block':'block' }
# def is_a_visual_mode(mode)
#     return has_key(visual_modes, mode)
# enddef
# 
# def do_nothing(...)
# enddef
# 
# # This can't be a script-only () function because it needs to be called from
# # the command-line.
# 
# def OperGetLine(col)
#     var position = getpos(".")
#     final result = { 'line':position[2], 'column':0 }
# 
#     if col != 0
#         final result['column'] = len(getline("."))
#     endif
# 
#     return result
# enddef
# 
# def PerformOperator(visual)
#     if OperatorChar isnot 0
#         get(OperatorList, OperatorChar, funcref('do_nothing'))['handler'](visual)
#         var OperatorChar = 0
#     endif
# enddef
# 
# def MakeOperator(char, func)
#     var func_holder = { 'func' : func }
#     def func_holder.handler(visual) dict
#         var mode = get(visual_modes, visual, 0)
# 
#         if visual != 'char' && mode isnot 0
#             var [start_mark, end_mark] = ["'<", "'>"]
#         else
#             var [start_mark, end_mark] = ["'[", "']"]
#             var mode = 'normal'
#         endif
# 
#         var [start_line, start_column] = getpos(start_mark)[1:2]
#         var [  end_line,   end_column] = getpos(  end_mark)[1:2]
#         # echoerr start_line .. " " .. end_line
#         var start = { 'line':start_line, 'column':start_column }
#         var   end = { 'line':  end_line, 'column':  end_column }
#         self['func'](mode, start, end)
#     enddef
# 
#     var char = char[0]
#     var OperatorList[char] = func_holder
#     # var escaped_char = substitute(char, '\', '\\\\', 'g')
# 
#     var normal_command = "nnoremap <silent> " .. char ..  " :let OperatorChar = '" .. char .. "'<CR>:set operatorfunc=PerformOperator<CR>g@"
#     var oper_func_get  = "OperatorList['" .. char .. "']['handler']"
#     var visual_command = "vnoremap <silent> " .. char ..  " :<C-U>" .. oper_func_get .. "(visualmode())<CR>"
# 
#     silent execute normal_command
#     silent execute visual_command
# enddef

# def Backslash(mode, start, end)
#     echo "Backslash " mode start end
# enddef

# nnoremap <silent> \\ :Backslash("normal", OperGetLine(0), OperGetLine(-1))<CR>
# nnoremap <silent> \/ :Backslash("normal", OperGetLine(0), OperGetLine(-1))<CR>
# MakeOperator('\', funcref('Backslash'))

# def OpenBracket(mode, start, end)
#     echo "Open bracket " mode start end
# enddef

# NOTE: So far I haven't been able to remap [[ and similar keymaps. I'm not sure
# why.
# nnoremap <silent> [[ :OpenBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
# nnoremap <silent> [] :OpenBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
# MakeOperator('[', funcref('OpenBracket'))

# def CloseBracket(mode, start, end)
#     echo "Close bracket" mode start end
# enddef

# nnoremap <silent> ]] :CloseBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
# nnoremap <silent> ][ :CloseBracket("normal", OperGetLine(0), OperGetLine(-1))<CR>
# MakeOperator(']', funcref('CloseBracket'))

# set indentexpr=CustomIndent()
# def CustomIndent()
#     var line_num = line(".")
#     var prev_lnum = line_num
#     var prev_line = ''
#     var prev_indent = 0
#     
#     while 1
#         var prev_lnum -= 1
# 
#         if prev_lnum <= 1
#             break
#         endif
# 
#         var prev_line = getline(prev_lnum)
#         if prev_line != ''
#             break
#         endif
#     endwhile
# 
#     var prev_indent = indent(prev_lnum)
# 
#     return cindent(line_num)
# enddef

# Re-source gvimrc when vimrc is reloaded
const gvim_path = join([dot_vim_path, 'gvimrc'], path_separator)
if has('gui') && filereadable(gvim_path)
    execute "source " .. gvim_path
endif

if exists('*g:LocalVimRCEnd')
    g:LocalVimRCEnd()
endif

# def g:TestVirtualText()
#     if len(prop_type_get('number')) == 0
#         prop_type_add('number', {'highlight': 'Constant'})
#     endif
#     const current_line = line('.')
#     const props = current_line->prop_list()
# 
# 
#     if len(props) > 0
#         current_line->prop_clear()
#     else
#         current_line->prop_add(0, {"type": "number", "text": "This is virtual text"})
#     endif
# enddef
# nnoremap <leader>v :call g:TestVirtualText()<CR>

defcompile