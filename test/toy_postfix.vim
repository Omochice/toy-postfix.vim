let s:suite = themis#suite('toy_postfix')
let s:scope = themis#helper('scope')
let s:parent = themis#suite('parent')
let s:funcs = s:scope.funcs('autoload/toy_postfix.vim')

let s:rule_dir = expand('<sfile>:p:h') .. '/rules'

function! s:suite.before() abort
  call mkdir(s:rule_dir, 'p')
  let l:vim_rules = [
        \ '[[rules]]',
        \ 'regex = "\\(\\S\\+\\)\\.if"',
        \ 'template = """',
        \ 'if {{__$1__}}',
        \ '  {{__cursor__}}',
        \ 'endif',
        \ '"""',
        \ ]
  call writefile(l:vim_rules, s:rule_dir .. '/vim.toml')

  let l:javascript_rule = [
        \ '[[rules]]',
        \ 'regex = "\\(\\S\\+\\)\\.if"',
        \ 'template = """',
        \ 'if ({{__$1__}}) {',
        \ '  {{__cursor__}}',
        \ '}',
        \ '"""',
        \ ]
  call writefile(l:javascript_rule, s:rule_dir .. '/javascript.toml')

  let l:typescript_rule = [
        \ '[[rules]]',
        \ 'regex = "\\(\\S\\+}\)\\.echo"',
        \ 'template = """',
        \ 'console.log({{__$1__}})',
        \ '"""',
        \ ]
  call writefile(l:typescript_rule, s:rule_dir .. '/typescript.toml')
  let g:toy_postfix#rule_dir = s:rule_dir
endfunction

function s:suite.before_each() abort
  enew!
endfunction

function s:suite.after() abort
  call delete(s:rule_dir, 'rf')
endfunction

function s:suite.after_each() abort
  unlet! g:toy_postfix#extends
  call deletebufline(1, '$')
endfunction

function! s:suite.__expand__() abort
  let l:expand_normal = themis#suite('If current line match rule, should be replaced (on normal mode)')
  function! l:expand_normal.test() abort
    set filetype=vim
    call setline(1, 'v:true.if')
    normal! $
    call toy_postfix#expand()
    let l:expected = [
          \ 'if v:true',
          \ '  ',
          \ 'endif'
          \ ]
    call assert_equal(l:expected, getline(1, 3))
  endfunction

  let l:expand_insert = themis#suite('If current line match rule, should be replaced (on insert mode)')
  function! l:expand_insert.test() abort
    enew!
    set filetype=vim
    call setline(1, 'v:true.if')
    normal! $
    execute 'startinsert!'
    call toy_postfix#expand()
    let l:expected = [
          \ 'if v:true',
          \ '  ',
          \ 'endif'
          \ ]
    call assert_equal(l:expected, getline(1, 3))
  endfunction

  let l:expand_curpos_normal = themis#suite('If rule template include "{{__cursor__}}", cursor should be moved at there (on normal mode)')
  function! l:expand_curpos_normal.test() abort
    set filetype=vim
    call setline(1, 'v:true.if')
    normal! $
    call toy_postfix#expand()
    call assert_equal([2, 3], getpos('.')[1:2])
  endfunction

  let l:expand_curpos_insert = themis#suite('If rule template include "{{__cursor__}}", cursor should be moved at there (on insert mode)')
  function! l:expand_curpos_insert.test() abort
    enew!
    set filetype=vim
    call setline(1, 'v:true.if')
    normal! $
    execute 'startinsert!'
    call toy_postfix#expand()
    call assert_equal([2, 3], getpos('.')[1:2])
  endfunction

  let l:unexpand_other_filetype = themis#suite('If the filetype is not found in rule dir, do nothing')
  function! l:unexpand_other_filetype.test() abort
    set filetype=text
    call setline(1, 'v:true.if')
    normal! $
    call toy_postfix#expand()
    call assert_equal('v:true.if', getline(1))
  endfunction

  let l:expand_extends_filetype = themis#suite('If set the filetype with extends, should be able call orginal rule too.')
  function! l:expand_extends_filetype.test() abort
    let g:toy_postfix#extends = { 'typescript': 'javascript' }
    set filetype=typescript
    call setline(1, 'true.if')
    normal! $
    call toy_postfix#expand()
    let l:expected = [
          \ 'if (true) {',
          \ '  ',
          \ '}'
          \ ]
    call assert_equal(l:expected, getline(1, 3))
  endfunction

  let l:expand_extends_multiple_filetype = themis#suite('If set the filetype with multiple extends, should be able call orginal rule too.')
  function! l:expand_extends_multiple_filetype.test() abort
    let g:toy_postfix#extends = { 'vue': ['typescript', 'javascript'] }
    set filetype=vue
    call setline(1, 'true.echo')
    normal! $
    call toy_postfix#expand()
    let l:expected = 'console.log(true)'
    call assert_equal(l:expected, getline(1))
  endfunction

  let l:part_of = themis#suite('If match with part of current line, should replace part of it.')
  function! l:part_of.test() abort
    set filetype=vim
    call setline(1, 'let v:true.if')
    normal! $
    call toy_postfix#expand()
    let l:expected = [
          \ 'let if v:true',
          \ '  ',
          \ 'endif'
          \ ]
    call assert_equal(l:expected, getline(1, 3))
  endfunction

  let l:indent_case = themis#suite('If current line has some indents, should keep it.')
  function! l:indent_case.test() abort
    set filetype=vim
    call setline(1, '  v:true.if')
    normal! $
    call toy_postfix#expand()
    let l:expected = [
          \ '  if v:true',
          \ '    ',
          \ '  endif'
          \ ]
    call assert_equal(l:expected, getline(1, 3))
  endfunction
endfunction

