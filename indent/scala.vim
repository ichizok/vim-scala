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

function! s:IsDeclStatement(line)
  return a:line =~ '^\s*\%(\<\%(override\|final\|\%(protected\|private\)\%(\[\w\+\]\)\?\)\s\+\)*\<\%(va[lr]\|def\)\>.*=\s*$'
        \ || a:line =~ '^\s*\<\%(\%(else\s\+\)\?if\|for\|while\)\>.*)\s*$'
        \ || a:line =~ '^\s*\<else\>\s*$'
endfunction

function! s:IsCaseClause(line)
  return a:line =~ '^\s*\<case\>.*=>'
        \ && a:line !~ '^\s*\<case\>\s*\<class\>'
endfunction

function! s:FindBrkPair(startbrk, endbrk, lnum)
    call cursor(a:lnum, 1)
    return searchpair(a:startbrk, '', a:endbrk, 'bnW', 
          \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
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
  if thisline =~ '^\s*[})]'
    let endbrk = matchstr(thisline, '[})]')
    let startbrk = endbrk == '}' ? '{' : '('
    let pairlnum = s:FindBrkPair(startbrk, endbrk, v:lnum)
    return indent(s:CountParens(getline(pairlnum)) < 0
          \ ? s:FindBrkPair('(', ')', pairlnum) : pairlnum)
  endif

  let prevline = getline(lnum)
  if prevline =~ '{[^{]*$'
    let pairlnum = s:FindBrkPair('{', '}', v:lnum)
    if pairlnum == lnum
      return indent(s:CountParens(getline(pairlnum)) < 0
            \ ? s:FindBrkPair('(', ')', pairlnum) : pairlnum) + &shiftwidth
    endif
  endif

  if prevline =~ '^\s*}[})]*\s*$'
    let domnlnum = prevnonblank(s:FindBrkPair('{', '}', lnum) - 1)
    return s:IsDeclStatement(getline(domnlnum)) ? ind - &shiftwidth : ind
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

  " Add a 'shiftwidth' after lines that start a block
  " If if, for or while end with ), this is a one-line block
  " If val, var, def end with =, this is a one-line block
  if s:IsDeclStatement(prevline)
        \ || s:IsCaseClause(prevline)
    let ind = ind + &shiftwidth
  endif

  " Dedent after if, for, while and val, var, def without block
  let pprevline = getline(prevnonblank(lnum - 1))
  if s:IsDeclStatement(pprevline)
    let ind = ind - &shiftwidth
  endif

  " If parenthesis are unbalanced, indent or dedent
  let nparens = s:CountParens(prevline)
  echo nparens
  if nparens > 0
    let ind = ind + &shiftwidth
  elseif nparens < 0
    let ind = ind - &shiftwidth
  endif

  return ind
endfunction
