let s:save_cpo = &cpo
set cpo&vim

let s:TOML = vital#toy_postfix#import('Text.TOML')

let s:rules = {}

let s:cache = {}

function! s:filetype() abort
  return &filetype
endfunction

function! toy_postfix#expand() abort
  let l:rule = s:get_rule()
  if l:rule->empty()
    return
  endif

  let l:current_line = line('.')
  let l:line = getline(l:current_line)
  let l:matches = l:line->matchlist(l:rule.regex)
  let l:out = l:rule.template
  for l:idx in range(l:matches->len())
    let l:placeholder = '{{__$' .. string(l:idx) .. '__}}'
    let l:out = l:out->substitute(l:placeholder, l:matches[l:idx], 'g')
  endfor
  let l:out = l:out->split('\n')

  let l:indent = l:line->matchstr('\s*')
  let l:out =  l:out->map({_, val -> l:indent .. v:val})
  let l:out[0] = l:line->substitute(l:rule.regex, '', '') .. l:out[0]->substitute('\s*', '', '')

  let l:curpos = getcursorcharpos()
  let l:cursor_marker = '{{__cursor__}}'
  for l:idx in range(l:out->len())
    let l:row = l:out[idx]
    if l:row =~# l:cursor_marker
      let l:curpos[1] += l:idx
      let l:curpos[2] = l:row->matchstrpos(l:cursor_marker)[1]
      let l:out[l:idx] = l:row->substitute(l:cursor_marker, '', '')
      break
    endif
  endfor
  silent! normal! "_dd
  call append(l:current_line-1, l:out)
  " NOTE: add col+1 because of between position of insert and normal one
  call setcursorcharpos(l:curpos[1], l:curpos[2]+1)
endfunction

function! toy_postfix#expandable() abort
  return !(s:get_rule()->empty())
endfunction

function! s:get_rule() abort
  let l:filetype = s:filetype()
  call s:load_rule(s:filetype())
  if !(s:rules->has_key(l:filetype))
    " NOTE: rule for filetype is undefined
    return {}
  endif

  let l:line = getline('.')

  " NOTE: If call this with same context, use cache.
  " This makes fast to execute like `expandable() ? expand() : other` mapping
  if (!(s:cache->empty())
        \ && s:cache->get('filetype') ==# l:filetype
        \ && s:cache->get('context') ==# l:line
        \ )
    return s:cache->get('rule')
  endif

  for l:rule in s:rules->get(l:filetype, {})->get('rules', [])
    if l:line =~# l:rule.regex
      let s:cache = { 'filetype': l:filetype, 'context': l:line, 'rule': l:rule->copy()}
      return l:rule
    endif
  endfor

  return {}
endfunction

function! s:load_rule(filetype) abort
  if a:filetype->empty()
    return
  endif

  if s:rules->has_key(a:filetype)
    return
  endif

  let l:loaded = s:load_toml_by_filetype(a:filetype)
  if !(l:loaded->empty())
    let s:rules[a:filetype] = l:loaded->deepcopy()
  endif

  " NOTE: if filetype has chain like typescript => javascript, load it too
  let l:extends = get(g:, 'toy_postfix#extends', {})->get(a:filetype, '')
  if l:extends->empty()
    return
  endif

  let l:RULE_KEY = 'rules'
  let l:extend_rule = s:rules->get(a:filetype, {})->get(l:RULE_KEY, [])

  if l:extends->type() ==# v:t_string
    " NOTE: like 'javascript'
    let l:loaded = s:load_toml_by_filetype(l:extends)
    let l:extend_rule = l:extend_rule->extend(
          \ l:loaded->get(l:RULE_KEY, [])
          \ )
  elseif l:extends->type() ==# v:t_list
    " NOTE: like ['javascript', 'typescript']
    for l:f in l:extends
      let l:loaded = s:load_toml_by_filetype(l:f)
      let l:extend_rule = l:extend_rule->extend(
            \ l:loaded->get(l:RULE_KEY, [])
            \ )
    endfor
  endif
  let s:rules[a:filetype] = { l:RULE_KEY: l:extend_rule->deepcopy() }
endfunction

function! s:load_toml_by_filetype(filetype) abort
  let l:rule_path = (get(g:, 'toy_postfix#rule_dir', $VIMRUNTIME) .. '/' .. a:filetype .. '.toml')->fnamemodify(':p')
  if filereadable(l:rule_path)
    return s:TOML.parse_file(l:rule_path)
  endif
  return {}
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et:
