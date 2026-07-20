{
  description = "Prelude — reusable flake-parts module for project development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
        # Dogfood the local module (avoid a circular flake input).
        ./modules/flake-module.nix
      ];

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
          # Demonstrate a named contribution shell: nix develop .#tools
          contributions.tools = {
            packages = [
              pkgs.jq
            ];
            commands = [
              {
                name = "prelude-info";
                help = "Print a short Prelude status line";
                command = "echo 'Prelude contribution shell: tools'";
              }
            ];
          };
        };
      };

      flake = {
        # Public module for other flakes:
        #   imports = [ inputs.prelude.flakeModules.default ];
        flakeModules.default = ./modules/flake-module.nix;
        # Alias used by some flakes in the ecosystem.
        flakeModule = ./modules/flake-module.nix;

        templates.default = {
          path = ./templates/default;
          description = "Minimal project shell using Prelude + devshell + direnv";
        };
      };
    };
}
