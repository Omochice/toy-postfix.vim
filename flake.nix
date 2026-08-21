{
  description = "A vim plugin that provides 'postfix completion' feature.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:Omochice/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-overlay = {
      url = "github:kawarimidoll/vim-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      flake-utils,
      nur-packages,
      vim-overlay,
      neovim-nightly-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nur-packages.overlays.default
          ];
        };
        treefmt = treefmt-nix.lib.evalModule pkgs (
          { ... }:
          {
            settings.global.excludes = [ ];
            settings.formatter = {
              # keep-sorted start block=yes
              rumdl = {
                command = "${pkgs.rumdl}/bin/rumdl";
                options = [ "fmt" ];
                includes = [ "*.md" ];
              };
              # keep-sorted end
            };
            programs = {
              # keep-sorted start block=yes
              keep-sorted.enable = true;
              nixfmt.enable = true;
              taplo.enable = true;
              toml-sort.enable = true;
              yamlfmt = {
                enable = true;
                settings = {
                  formatter = {
                    type = "basic";
                    retain_line_breaks_single = true;
                  };
                };
              };
              # keep-sorted end
            };
          }
        );
        runAs =
          name: runtimeInputs: text:
          let
            program = pkgs.writeShellApplication {
              inherit name runtimeInputs text;
            };
          in
          {
            type = "app";
            program = "${program}/bin/${name}";
          };
        themisFor = editor: [
          editor
          pkgs.vimPlugins.vim-themis
        ];
        devPackages = rec {
          # keep-sorted start block=yes
          actions = with pkgs; [
            actionlint
            ghalint
            zizmor
          ];
          renovate-config-validator = with pkgs; [
            renovate
          ];
          themis = with pkgs; [
            neovim
            vim
            vimPlugins.vim-themis
          ];
          # keep-sorted end
          default = [
            treefmt.config.build.wrapper
          ]
          ++ actions
          ++ renovate-config-validator
          ++ themis;
        };
      in
      {
        # keep-sorted start block=yes
        apps = {
          check-actions = pkgs.lib.pipe ''
            actionlint
            ghalint run
            zizmor .github
          '' [ (runAs "check-action" devPackages.actions) ];
          check-renovate-config = pkgs.lib.pipe ''
            renovate-config-validator --strict renovate.json5
          '' [ (runAs "check-renovate-config" devPackages.renovate-config-validator) ];
          test-neovim = pkgs.lib.pipe ''
            THEMIS_VIM=nvim themis --reporter dot "$@"
          '' [ (runAs "test-neovim" (themisFor pkgs.neovim)) ];
          test-neovim-nightly = pkgs.lib.pipe ''
            THEMIS_VIM=nvim themis --reporter dot "$@"
          '' [ (runAs "test-neovim-nightly" (themisFor neovim-nightly-overlay.packages.${system}.neovim)) ];
          test-vim = pkgs.lib.pipe ''
            THEMIS_VIM=vim themis --reporter dot "$@"
          '' [ (runAs "test-vim" (themisFor pkgs.vim)) ];
          test-vim-nightly = pkgs.lib.pipe ''
            THEMIS_VIM=vim themis --reporter dot "$@"
          '' [ (runAs "test-vim-nightly" (themisFor vim-overlay.packages.${system}.vim)) ];
        };
        checks = {
          formatting = treefmt.config.build.check self;
        };
        devShells = pkgs.lib.pipe devPackages [
          (pkgs.lib.attrsets.mapAttrs (name: buildInputs: pkgs.mkShell { inherit buildInputs; }))
        ];
        formatter = treefmt.config.build.wrapper;
        # keep-sorted end
      }
    );
}
