" Vim indent file
" Language   : Scala (http://scala-lang.org/)
" Maintainer : Stefan Matthias Aust
" Last Change: 2006 Apr 13

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

let b:undo_indent = 'setl cin< cino< indentexpr< indentkeys<'

setlocal indentexpr=GetScalaIndent()

setlocal indentkeys=0{,0},0),!^F,<>>,o,O,<Return>,0=extends,0=with

if exists("*GetScalaIndent")
  finish
endif

function! s:FindBrkPair(startbrk, endbrk)
    call cursor(v:lnum, 1)
    return searchpair(a:startbrk, '', a:endbrk, 'bnW', 
          \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
endfunction

function! s:IsCaseClause(line)
  return a:line =~ '^\s*\<case\>.*=>'
        \ && a:line !~ '^\s*\<case\>\s*\<class\>'
endfunction

function! s:CountParens(line)
  let line = substitute(a:line, '"\%(.\|\\"\)*"', '', 'g')
  let open = substitute(line, '[^(]', '', 'g')
  let close = substitute(line, '[^)]', '', 'g')
  return strlen(open) - strlen(close)
endfunction

function! GetScalaIndent()
  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)
  let ind = indent(lnum)

  " Hit the start of the file, use zero indent.
  if ind == -1
    return 0
  endif

  let thisline = getline(v:lnum)
  let endbrk = matchstr(thisline, '^\s*[})]')
  if strlen(endbrk)
    let endbrk = substitute(endbrk, '^\s*', '', '')
    let startbrk = endbrk == '}' ? '{' : '('
    return indent(s:FindBrkPair(startbrk, endbrk))
  endif

  let prevline = getline(lnum)
  let startbrk = matchstr(prevline, '[{(]')
  if strlen(startbrk)
    let endbrk = startbrk == '{' ? '}' : ')'
    call cursor(v:lnum, 1)
    if s:FindBrkPair(startbrk, endbrk) == lnum
      return ind + &shiftwidth
    endif
  endif

  " Subtract a 'shiftwidth' on html
  if thisline =~ '^\s*</[a-zA-Z][^>]*>'
        \ || s:IsCaseClause(thisline)
    let ind = ind - &shiftwidth
  endif

  "Indent html literals
  if prevline !~ '/>\s*$'
        \ && prevline =~ '<[a-zA-Z][^>]*>\s*$'
    return ind + &shiftwidth
  endif

  let acsspc = '\<\%(public\|protected\|private\)\?\>.*'

  " Add a 'shiftwidth' after lines that start a block
  " If if, for or while end with ), this is a one-line block
  " If val, var, def end with =, this is a one-line block
  if prevline =~ '^\s*\<\%(\%(else\s\+\)\?if\|for\|while\)\>.*)\s*$'
        \ || prevline =~ '^\s*'.acsspc.'\<\%(va[lr]\|def\)\>.*=\s*$'
        \ || prevline =~ '^\s*\<else\>\s*$'
        \ || s:IsCaseClause(prevline)
    let ind = ind + &shiftwidth
  endif

  " If parenthesis are unbalanced, indent or dedent
  let cnt = s:CountParens(prevline)
  echo cnt
  if cnt > 0
    let ind = ind + &shiftwidth
  elseif cnt < 0
    let ind = ind - &shiftwidth
  endif
  
  " Dedent after if, for, while and val, var, def without block
  let pprevline = getline(prevnonblank(lnum - 1))
  if pprevline =~ '^\s*\<\%(\%(else\s\+\)\?if\|for\|while\)\>.*)\s*$'
        \ || pprevline =~ '^\s*'.acsspc.'\<\%(va[lr]\|def\)\>.*=\s*$'
        \ || pprevline =~ '^\s*\<else\>\s*$'
    let ind = ind - &shiftwidth
  endif

  return ind
endfunction
