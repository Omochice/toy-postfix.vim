# Contributing

## Running the tests

The test suite is written for [vim-themis](https://github.com/thinca/vim-themis).
Vim, Neovim and vim-themis itself are provided by the Nix flake, so a clean checkout needs no further installation.

Each editor has its own app, and the following two cover the versions packaged in nixpkgs:

```console
nix run .#test-vim
nix run .#test-neovim
```

The head builds of both editors are available as well, and CI runs all four:

```console
nix run .#test-vim-nightly
nix run .#test-neovim-nightly
```

Every app forwards its extra arguments to `themis`, so a single file can be targeted:

```console
nix run .#test-vim -- test/toy_postfix.vim
```

## Working interactively

The `themis` development shell puts `vim`, `nvim` and `themis` on `PATH`, which is useful when the same test is run repeatedly:

```console
nix develop .#themis
```

## Formatting

All formatters are wired into treefmt, so the whole tree is formatted by a single command:

```console
nix fmt
```

`nix flake check` runs the flake's checks, which include a formatting check.
