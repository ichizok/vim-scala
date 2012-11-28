" Vim plugin that generates new Scala source file when you type
"    vim nonexistent.scala.
" Scripts tries to detect package name from the directory path, e. g.
" .../src/main/scala/com/mycompany/myapp/app.scala gets header
" package com.mycompany.myapp
"
" Author     :   Stepan Koltsov <yozh@mx1.ru>

if exists('g:loaded_vim_scala')
  finiah
endif

let s:save_cpo = &cpo
set cpo&vim

function! MakeScalaFile()
  if exists('b:applied_scala_template')
    return
  endif

  let b:applied_scala_template = 1

  let filepath = expand('<afile>:p')
  let class = fnamemodify(filepath, ':t:r')
  let cpath = fnamemodify(filepath, ':h')

  let pos = matchend(cpath, '^\(.*/\)\?src/')
  if pos != -1
    let cpath = substitute(cpath[pos :], '^main/scala\(/\|$\)', '', '')
    if cpath[0] != ''
      let cpath = substitute(cpath, '/', '.', 'g')
      call append('0', 'package ' . cpath)
    endif
  endif

  call append(line('.'), ['class ' . class . ' {', '}'])

endfunction

augroup plugin-vim-scala
  au!
  au BufNewFile *.scala call MakeScalaFile()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_vim_scala = 1
