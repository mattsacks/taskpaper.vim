" plugin to handle the TaskPaper to-do list format
" Language:	Taskpaper (http://hogbaysoftware.com/projects/taskpaper)
" Maintainer:	David O'Callaghan <david.ocallaghan@cs.tcd.ie>
" URL:		https://github.com/davidoc/taskpaper.vim
" Last Change:  2011-09-28

if exists("b:loaded_task_paper")
    finish
endif
let b:loaded_task_paper = 1

" Define a default date format
if !exists('task_paper_date_format') | let task_paper_date_format = "%Y-%m-%d" | endif

"add '@' to keyword character set so that we can complete contexts as keywords
setlocal iskeyword+=@-@

"set default folding: by project (syntax), open (up to 99 levels), disabled 
setlocal foldmethod=syntax
setlocal foldlevel=99
setlocal nofoldenable

"show tasks from context under the cursor
function! s:ShowContext()
    let s:wordUnderCursor = expand("<cword>")
    if(s:wordUnderCursor =~ "@\k*")
        let @/ = "\\<".s:wordUnderCursor."\\>"
        "adapted from http://vim.sourceforge.net/tips/tip.php?tip_id=282
        setlocal foldexpr=(getline(v:lnum)=~@/)?0:1
        setlocal foldmethod=expr foldlevel=0 foldcolumn=1 foldminlines=0
        setlocal foldenable
    else
        echo "'" s:wordUnderCursor "' is not a context."    
    endif
endfunction

function! s:ShowAll()
    setlocal foldmethod=syntax
    %foldopen!
    setlocal nofoldenable
endfunction  

function! s:FoldAllProjects()
    setlocal foldmethod=syntax
    setlocal foldenable
    %foldclose! 
endfunction

" show project from context under cursor
function! s:ShowProject()
    let project  = getline('.')
    let position = getpos('.')
    let synlist  = []
    for id in synstack(position[1], position[2])
        call add(synlist, synIDattr(id, "name"))
    endfor
    if project =~ ':$' ||
                \ index(synlist, 'taskpaperProjectFold') != -1
        setl foldenable
        setl foldmethod=syntax
        %foldclose!
        exec 'normal zO'
    else
        echomsg project.' is not a project'
    endif
endfunction

" toggle @done context tag on a task
function! s:ToggleDone()

    let line = getline(".")
    if (line =~ '^\s*- ') || (line =~ '^\s*[^\-].\+:')
        let repl = line
        if (line =~ '@done')
            let repl = substitute(line, ' @done\%((.\{-})\)\=\(.*\)\=$', '\1', 'g')
            echomsg "undone!"
        else
            let today = strftime(g:task_paper_date_format, localtime())
            let done_str = " @done(" . today . ")"
            let repl = substitute(line, "$", done_str, "g")
            echomsg "done!"
        endif
        call setline(".", repl)
    else 
        echomsg "not a task."
    endif

endfunction

" toggle @cancelled context tag on a task
function! s:ToggleCancelled()

    let line = getline(".")
    if (line =~ '^\s*- ')
        let repl = line
        if (line =~ '@cancelled')
            let repl = substitute(line, "@cancelled\(.*\)", "", "g")
            echo "uncancelled!"
        else
            let today = strftime(g:task_paper_date_format, localtime())
            let cancelled_str = " @cancelled(" . today . ")"
            let repl = substitute(line, "$", cancelled_str, "g")
            echo "cancelled!"
        endif
        call setline(".", repl)
    else 
        echo "not a task."
    endif
endfunction

" substitute a tag for a line number
function! s:SubTag(tag, line)
  let line = getline(a:line)
  if line =~ '^\s*- '
    if line =~ a:tag
      let repl = substitute(line, ' @'.a:tag.'\(.*\)$', '\1', 'g')
    else
      let repl = substitute(line, '$', ' @'.a:tag, 'g')
    endif
    call setline(a:line, repl)
  endif
endfunction

" custom toggle @ tag
function! s:ToggleTag(tag, line1, line2)
  for l in range(a:line1, a:line2)
    call s:SubTag(a:tag, l)
  endfor
endfunction
command! -nargs=1 -range -buffer Tag
      \ :exec 'let s:c = getpos(".")'
      \| call s:ToggleTag(<f-args>, <line1>, <line2>)
      \| call setpos('.', s:c)

" Set up mappings
noremap <unique> <script> <Plug>ToggleDone      :call <SID>ToggleDone()<CR>
noremap <unique> <script> <Plug>ToggleCancelled :call <SID>ToggleCancelled()<CR>
noremap <unique> <script> <Plug>ShowContext     :call <SID>ShowContext()<CR>
noremap <unique> <script> <Plug>ShowAll         :call <SID>ShowAll()<CR>
noremap <unique> <script> <Plug>ShowProject     :call <SID>ShowProject()<CR>

map <buffer> <silent> <Leader>td <Plug>ToggleDone
map <buffer> <silent> <Leader>tx <Plug>ToggleCancelled
map <buffer> <silent> <Leader>tc <Plug>ShowContext
map <buffer> <silent> <Leader>ta <Plug>ShowAll
map <buffer> <silent> <Leader>tp <Plug>ShowProject

nno <buffer> <silent> <Leader>tt :Tag<Space>
xno <buffer> <silent> <Leader>tt :Tag<Space>
