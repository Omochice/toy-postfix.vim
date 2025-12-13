[![vim-themis](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml/badge.svg)](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml)

# toy-postfix.vim

This plugin provides 'postfix completion' feature.

## Installation

You can use your favorite plugin managers.

- [vim-plug](https://github.com/junegunn/vim-plug)

  ```vim
  Plug 'Omochice/toy-postfix.vim'
  ```

- [vim-jetpack](https://github.com/tani/vim-jetpack)

  ```vim
  Jetpack 'Omochice/toy-postfix.vim'
  ```

- [dein.vim](https://github.com/Shougo/dein.vim)

  ```vim
  call dein#add('Omochice/toy-postfix.vim')
  ```

## Usage

To perform this plugin, need to write setting file.

Setting file is format as TOML.

The files must be into `g:toy_postfix#rule_dir`.

Rule format is like below:

```toml
[[rules]]
regex = "\\(\\S\\+\\)\\.if"
template = """
if {{__$1__}}
  {{__cursor__}}
endif
"""
```

First, this contents save as `g:toy_postfix#rule_dir/vim.toml` and move cursor

on line that `v:true.if` in `.vim` file.

Execute `call toy_postfix#expand()`, the line will be like below:

```vim
v:true.if
```

This will be:

```vim
if v:true
  |
endif
```

('|' means cursor position.)

## Variables

- `g:toy_postfix#rule_dir`

  Path to directory that include rule toml files.

  Default: $VIMRUNTIME

- `g:toy_postfix#extends`

  The setting for language that depends other language's setting.

  Like typescript-javascript etc.

  Default: {}

  If you want to use rule for javascript on typescript too, write like below:

  ```vim
  let g:toy_postfix#extends = { 'typescript': 'javascript', }
  ```

  If you want to use multiple dependencies, write like below:

  ```vim
  let g:toy_postfix#extends = { 'vue': ['typescript', 'javascript'] }
  ```

  NOTE: This option DOES NOT register recursively.

## Functions

- `toy_postfix#expandable()`

  The function that return whether current line is expandable.

- `toy_postfix#expand()`

  The function that expand current line using rule.
  If rule that match with current line does not exists, do nothing.

## License

[MIT](./LICENSE)

## Coverage

Currently, there are tested on Linux only.

|       |vim|nvim|
|-------|---|----|
|stable |[![coverage-vim-stable](https://omochice.github.io/toy-postfix.vim/badge-Linux-vim-stable.svg)](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml)|[![coverage-nvim-stable](https://omochice.github.io/toy-postfix.vim/badge-Linux-neovim-stable.svg)](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml)|
|nightly|[![coverage-vim-nightly](https://omochice.github.io/toy-postfix.vim/badge-Linux-vim-nightly.svg)](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml)|[![coverage-nvim-nightly](https://omochice.github.io/toy-postfix.vim/badge-Linux-neovim-nightly.svg)](https://github.com/Omochice/toy-postfix.vim/actions/workflows/ci.yml)|
