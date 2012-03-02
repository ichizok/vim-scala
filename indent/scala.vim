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

function! s:is_case_clause(line)
  return a:line =~ '^\s*\<case\>.\{-}=>'
        \ && a:line !~ '\<class\>'
endfunction

function! s:is_sentense_continued(line)
  if a:line =~ '^\s*\%(\%(else\s\+\)\?if\|for\|while\)\s*('
    let colm = stridx(a:line, '(')
    let obvs = 1
    for i in range(colm + 1, strlen(a:line) - 1)
      if a:line[i] == '('
        let obvs += 1
      elseif a:line[i] == ')'
        let obvs -= 1
      endif
      if obvs == 0
        let colm = i
        break
      endif
    endfor
    return match(a:line, ')\s*$', colm) != -1
  endif
  return a:line =~ '\<\%(va[lr]\|def\)\>.\{-}=\s*$'
        \ || a:line =~ '^\s*else\s*$'
endfunction

function! s:find_parens_pair(openp, closep, ...)
  let lnum = a:0 >= 1 ? a:1 : v:lnum
  let colm = a:0 >= 2 ? a:2 : 1
  call cursor(lnum, colm)
  return searchpair(a:openp, '', a:closep, 'bnW',
        \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
endfunction

function! s:count_parens(line)
  let line = substitute(a:line, '".\{-}[^\\]\?"', '', 'g')
  let open = substitute(line, '[^(]', '', 'g')
  let close = substitute(line, '[^)]', '', 'g')
  return strlen(open) - strlen(close)
endfunction

function! s:get_virtline(lnum)
  let lnum = a:lnum
  let line = getline(lnum)
  let nparens = s:count_parens(line)
  if nparens < 0
    let lnum = s:find_parens_pair('(', ')', lnum)
    let line = getline(lnum).line
  endif
  return [lnum, line, nparens]
endfunction

function! GetScalaIndent()
  " Find a non-blank line above the current line.
  let prevlnum = prevnonblank(v:lnum - 1)
  let ind = indent(prevlnum)

  " Hit the start of the file, use zero indent.
  if ind == -1
    return 0
  endif

  let currline = getline(v:lnum)
  if currline =~ '^\s*[})]'
    let closep = matchstr(currline, '[})]')
    let openp = closep == '}' ? '{' : '('
    let pairlnum = s:find_parens_pair(openp, closep)
    if pairlnum != v:lnum
      let ind = indent(s:count_parens(getline(pairlnum)) < 0
            \ ? s:find_parens_pair('(', ')', pairlnum) : pairlnum)
      return getline(pairlnum) =~ '^\s*\<\%(extends\|with\)\>'
            \ ? ind - &shiftwidth * 2 : ind
    endif
  endif

  " If parenthesis are unbalanced, indent or dedent
  let [prevlnum, prevline, nparens] = s:get_virtline(prevlnum)
  if nparens > 0
    return ind + &shiftwidth
  elseif nparens < 0
    let ind = indent(prevlnum)
  endif

  if currline =~ '^\s*\<\%(extends\|with\)\>'
    if prevline =~ '\<\%(class\|object\|trait\)\>'
      return ind + &shiftwidth * 2
    elseif s:count_parens(prevline) < 0
      return ind + &shiftwidth
    endif
    return ind
  endif

  if prevline =~ '^\s*\<\%(extends\|with\)\>'
    return ind - &shiftwidth * (prevline =~ '{\s*$' ? 1 : 2)
  endif

  if prevline =~ '{[^{}]*$'
    if s:count_parens(prevline) < 0
      let ind = indent(s:find_parens_pair('(', ')', prevlnum))
    endif
    return ind + &shiftwidth
  endif

  if prevline =~ '^\s*}[})]*\s*$'
    let domnlnum = prevnonblank(s:find_parens_pair('{', '}', prevlnum) - 1)
    return s:is_sentense_continued(s:get_virtline(domnlnum)[1])
          \ ? ind - &shiftwidth : ind
  endif

  " Subtract a 'shiftwidth' on html
  if currline =~ '^\s*</[a-zA-Z][^>]*>'
    let ind = ind - &shiftwidth
  endif

  if s:is_case_clause(currline)
    let domnlnum = s:find_parens_pair('{', '}')
    return indent(domnlnum) + &shiftwidth
  endif

  "Indent html literals
  if prevline !~ '/>\s*$'
        \ && prevline =~ '<[a-zA-Z][^>]*>\s*$'
    return ind + &shiftwidth
  endif

  " Add a 'shiftwidth' after lines that start a block
  " If if, for or while end with ), this is a one-line block
  " If val, var, def end with =, this is a one-line block
  if s:is_sentense_continued(prevline)
        \ || s:is_case_clause(prevline)
    let ind = ind + &shiftwidth
  endif

  " Dedent after if, for, while and val, var, def without block
  let pprevlnum = prevnonblank(prevlnum - 1)
  if s:is_sentense_continued(s:get_virtline(pprevlnum)[1])
    let ind = ind - &shiftwidth
  endif

  return ind
endfunction
