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

function! s:is_sentense_continued(lnum)
  let line = getline(a:lnum)
  let closep = match(line, ')\s*$') + 1
  if closep > 0
    call cursor(a:lnum, closep)
    let [lnum, colm] = searchpairpos('(', '', ')', 'bnW',
          \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
    let line = getline(lnum)
    return strpart(line, 0, colm) =~ '^\s*\<\%(\%(else\s\+\)\?if\|for\|while\)\s*($'
  endif
  return line =~ '\<\%(va[lr]\|def\)\>.\{-}=\s*$'
        \ || line =~ '^\s*else\s*$'
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

  let prevline = getline(prevlnum)
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

  if prevline =~ '{[^{]*$'
    let pairlnum = s:find_parens_pair('{', '}')
    if pairlnum == prevlnum
      return indent(s:count_parens(getline(pairlnum)) < 0
            \ ? s:find_parens_pair('(', ')', pairlnum) : pairlnum) + &shiftwidth
    endif
  endif

  if prevline =~ '^\s*}[})]*\s*$'
    let domnlnum = prevnonblank(s:find_parens_pair('{', '}', prevlnum) - 1)
    return s:is_sentense_continued(domnlnum) ? ind - &shiftwidth : ind
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
  if s:is_sentense_continued(prevlnum)
        \ || s:is_case_clause(prevline)
    let ind = ind + &shiftwidth
  endif

  " If parenthesis are unbalanced, indent or dedent
  let nparens = s:count_parens(prevline)
  if nparens > 0
    return ind + &shiftwidth
  elseif nparens < 0
    let prevlnum = s:find_parens_pair('(', ')', prevline)
    let ind = ind - &shiftwidth
  endif

  " Dedent after if, for, while and val, var, def without block
  let pprevlnum = prevnonblank(prevlnum - 1)
  if s:is_sentense_continued(pprevlnum)
    let ind = ind - &shiftwidth
  endif

  return ind
endfunction
