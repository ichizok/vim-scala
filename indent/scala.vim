" Vim indent file
" Language   : Scala (http://scala-lang.org/)
" Maintainer : Stefan Matthias Aust, etc.
" Last Change: 2012 Dec 13

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetScalaIndent()
setlocal indentkeys=0{,0},0),!^F,<>>,o,O,<Return>,0=extends,0=with

let b:undo_indent = 'setlocal
      \ autoindent<
      \ expandtab<
      \ indentexpr< 
      \ indentkeys<
      \ shiftwidth<
      \ tabstop<
      \'

if exists("*GetScalaIndent")
  finish
endif
let s:keepcpo= &cpo
set cpo&vim

function! s:skip_blank_and_comments(lnum)
  let lnum = a:lnum
  while lnum >= 1
    let lnum = prevnonblank(lnum)
    let head = match(getline(lnum), '\S\zs')
    if synIDattr(synID(lnum, head, 0), 'name') !~? 'string\|comment'
      break
    endif
    let lnum -= 1
  endwhile
  return lnum
endfunction

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

function! s:find_parens_pair(parens, ...)
  let bgnp = a:parens[0]
  let endp = a:parens[1]
  let lnum = a:0 >= 1 ? a:1 : v:lnum
  let colm = a:0 >= 2 ? a:2 : 1
  let pos = getpos('.')
  call cursor(lnum, colm)
  let parenspos = searchpair(bgnp, '', endp, 'bnW',
        \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? "string\\|comment"')
  call cursor(pos)
  return parenspos
endfunction

function! s:count_parens(line)
  let line = substitute(a:line, '".\{-}[^\\]\?"', '', 'g')
  let open = substitute(line, '[^(]', '', 'g')
  let close = substitute(line, '[^)]', '', 'g')
  return strlen(open) - strlen(close)
endfunction

function! s:get_bound_sentence(lnum)
  let lnum = a:lnum
  let line = getline(lnum)
  let nparens = s:count_parens(line)
  if nparens < 0
    let lnum = s:find_parens_pair('()', lnum)
    let line = getline(lnum).line
  endif
  return [lnum, line, nparens]
endfunction

function! GetScalaIndent()
  " If we're in the middle of a comment then just trust cindent
  let currline = getline(v:lnum)
  if currline =~ '^\s*\*'
    return cindent(v:lnum)
  endif

  " Find a non-blank/comment line above the current line.
  let prevlnum = s:skip_blank_and_comments(v:lnum - 1)
  let indt = indent(prevlnum)

  " Hit the start of the file, use zero indent.
  if indt == -1 | return 0 | endif

  let idx = match(currline, '^\s*\zs[})]')
  if idx >= 0
    let parens = currline[idx] == '}' ? '{}' : '()'
    let pairlnum = s:find_parens_pair(parens)
    if pairlnum != v:lnum
      let indt = indent(s:count_parens(getline(pairlnum)) < 0
            \ ? s:find_parens_pair('()', pairlnum) : pairlnum)
      return getline(pairlnum) =~ '^\s*\<\%(extends\|with\)\>'
            \ ? indt - &shiftwidth * 2 : indt
    endif
  endif

  " If parenthesis are unbalanced, indent or dedent
  let [prevlnum, prevline, nparens] = s:get_bound_sentence(prevlnum)
  if nparens > 0
    return indt + &shiftwidth
  elseif nparens < 0
    let indt = indent(prevlnum)
  endif

  if currline =~ '^\s*\<\%(extends\|with\)\>'
    if prevline =~ '\<\%(class\|object\|trait\)\>'
      return indt + &shiftwidth * 2
    elseif s:count_parens(prevline) < 0
      return indt + &shiftwidth
    endif
    return indt
  endif

  if prevline =~ '^\s*\<\%(extends\|with\)\>'
    return indt - &shiftwidth * (prevline =~ '{\s*$' ? 1 : 2)
  endif

  if prevline =~ '{[^{}]*$'
    if s:count_parens(prevline) < 0
      let indt = indent(s:find_parens_pair('()', prevlnum))
    endif
    return indt + &shiftwidth
  endif

  if prevline =~ '^\s*}[})]*\s*$'
    let domnlnum = prevnonblank(s:find_parens_pair('{}', prevlnum) - 1)
    return s:is_sentense_continued(s:get_bound_sentence(domnlnum)[1])
          \ ? indt - &shiftwidth : indt
  endif

  " Subtract a 'shiftwidth' on html
  if currline =~ '^\s*</[a-zA-Z][^>]*>'
    let indt = indt - &shiftwidth
  endif

  if s:is_case_clause(currline)
    let domnlnum = s:find_parens_pair('{}')
    return indent(domnlnum) + &shiftwidth
  endif

  "Indent html literals
  if prevline !~ '/>\s*$'
        \ && prevline =~ '<[a-zA-Z][^>]*>\s*$'
    return indt + &shiftwidth
  endif

  " Add a 'shiftwidth' after lines that start a block
  " If if, for or while end with ), this is a one-line block
  " If val, var, def end with =, this is a one-line block
  if s:is_sentense_continued(prevline)
        \ || s:is_case_clause(prevline)
    let indt = indt + &shiftwidth
  endif

  " Dedent after if, for, while and val, var, def without block
  let pprevlnum = prevnonblank(prevlnum - 1)
  if s:is_sentense_continued(s:get_bound_sentence(pprevlnum)[1])
    let indt = indt - &shiftwidth
  endif

  return indt
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
