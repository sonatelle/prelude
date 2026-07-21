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
  };

  outputs = inputs @ {flake-parts, ...}: let
    # Core only: no language packs (import flakeModules.go / … as needed).
    coreModule = {
      imports = [
        inputs.devshell.flakeModule
        ./modules/flake-module.nix
      ];
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [coreModule];

      # nixos-unstable no longer supports x86_64-darwin (dropped in 26.11).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;

        prelude = {
          enable = true;
          name = "prelude";
          packages = [
            pkgs.nil
            pkgs.nixfmt
            pkgs.statix
            pkgs.deadnix
          ];
        };
      };

      flake = {
        # Public modules for other flakes.
        flakeModules.default = coreModule;
        # Alias used by some flakes in the ecosystem.
        flakeModule = coreModule;

        # Language packs (optional). Reads project input `go-overlay`.
        #   inputs.go-overlay.url = "github:purpleclay/go-overlay";
        #   imports = [
        #     inputs.prelude.flakeModules.default
        #     inputs.prelude.flakeModules.go
        #   ];
        flakeModules.go = ./modules/prelude/languages/go;

        templates.default = {
          path = ./templates/default;
          description = "Minimal project shell using Prelude + devshell + direnv";
        };

        templates.go = {
          path = ./templates/go;
          description = "Go project shell using Prelude language pack (go-overlay + tools)";
        };
      };
    };
}
