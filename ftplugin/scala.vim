" Vim filetype plugin file
" Language   : Scala (http://scala-lang.org/)
" Maintainer : Stefan Matthias Aust, etc.
" Last Change: 2012 Dec 13

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:save_cpo = &cpo
set cpo-=C

setlocal et sw=2 ts=4
setlocal include=^import

" Undo the stuff we changed.
let b:undo_ftplugin = 'setlocal
      \ suffixes<
      \ suffixesadd<
      \ formatoptions<
      \ comments<
      \ commentstring<
      \ includeexpr<
      \'

" For filename completion, prefer the .java extension over the .class
" extension.
set suffixes+=.class

" Enable gf on import statements.  Convert . in the package
" name to / and append .java to the name, then search the path.
setlocal includeexpr=substitute(v:fname,'\\.','/','g')
setlocal suffixesadd=.scala

" Set 'formatoptions' to break comment lines but not other lines,
" and insert the comment leader when hitting <CR> or using "o".
setlocal formatoptions-=t formatoptions+=croql

" Set 'comments' to format dashed lists in comments. Behaves just like C.
setlocal comments& comments^=sO:*\ -,mO:*\ \ ,exO:*/
setlocal commentstring=//%s

" Restore the saved compatibility options.
let &cpo = s:save_cpo
unlet s:save_cpo
