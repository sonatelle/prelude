{
  description = "Go project shell via Sonatelle Prelude";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    prelude.url = "github:sonatelle/prelude";
    # Share the consumer nixpkgs with Prelude (and its nested devshell / go-overlay).
    prelude.inputs.nixpkgs.follows = "nixpkgs";
    prelude.inputs.flake-parts.follows = "flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.prelude.flakeModules.default
      ];

      # nixos-unstable no longer supports x86_64-darwin (dropped in 26.11).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {
        prelude = {
          enable = true;
          name = "go";

          languages.go = {
            enable = true;
            # version = "stable";           # default
            # version = "mod"; goMod = ./go.mod;
            # tools.enable = true;          # default: gopls, delve, gofumpt, …
            # tools.autoConfig = false;     # set true to bootstrap .golangci.yml if missing
          };
        };
      };
    };
}
