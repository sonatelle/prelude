{
  description = "Prelude — reusable flake-parts module for project development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Prefer nixpkgs.lib from the same tree as nixpkgs.
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    devshell.url = "github:numtide/devshell";
    # Share one nixpkgs with devshell (avoids a second pinned tree).
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Dogfood-only: pre-commit hooks (not part of flakeModules.default).
    # git-hooks.nix still needs the pre-commit runner; it is provided via the
    # dogfood shell / nix store — no system-wide install required.
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}: let
    # Core only: no language packs (import flakeModules.go / … as needed).
    # Do not import git-hooks here — projects using Prelude should not inherit it.
    coreModule = {
      imports = [
        inputs.devshell.flakeModule
        ./modules/flake-module.nix
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        coreModule
        inputs.git-hooks.flakeModule
      ];

      # nixos-unstable no longer supports x86_64-darwin (dropped in 26.11).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        pre-commit.settings.hooks = {
          # Writes files (same as `nix fmt` / alejandra).
          alejandra.enable = true;
          deadnix.enable = true;
          nil.enable = true;
          statix = {
            enable = true;
            settings.config = toString ./statix.toml;
          };
        };

        prelude = {
          enable = true;
          name = "prelude";
          packages =
            # pre-commit CLI (for `pre-commit run -a`) + hook tool packages
            [pkgs.pre-commit]
            ++ config.pre-commit.settings.enabledPackages;
        };

        # Install .git/hooks/pre-commit when entering the dogfood shell.
        devshells.default.devshell.startup.pre-commit.text =
          config.pre-commit.installationScript;
      };

      flake = {
        flakeModules.default = coreModule;
        flakeModule = coreModule;

        # Language packs (optional). Project inputs: go-overlay / rust-overlay /
        # nixpkgs-python.
        flakeModules.go = ./modules/prelude/languages/go;
        flakeModules.rust = ./modules/prelude/languages/rust;
        flakeModules.python = ./modules/prelude/languages/python;

        templates.default = {
          path = ./templates/default;
          description = "Minimal project shell using Prelude + devshell + direnv";
        };

        templates.go = {
          path = ./templates/go;
          description = "Go project shell using Prelude language pack (go-overlay + tools)";
        };

        templates.rust = {
          path = ./templates/rust;
          description = "Rust project shell using Prelude language pack (rust-overlay + tools)";
        };

        templates.python = {
          path = ./templates/python;
          description = "Python project shell using Prelude language pack (nixpkgs-python + tools)";
        };
      };
    };
}
