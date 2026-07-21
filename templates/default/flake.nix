{
  description = "Project development shell via Sonatelle Prelude";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    prelude.url = "github:sonatelle/prelude";
    # Share this project's nixpkgs with Prelude (and its nested devshell).
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
          name = "dev";
          packages = [
            # Add project tools here, e.g. pkgs.jq (bind pkgs in the lambda)
          ];
          # env = [ { name = "EXAMPLE"; value = "1"; } ];
          # commands = [ { name = "hello"; help = "say hi"; command = "echo hi"; } ];
          # Language packs: nix flake init -t github:sonatelle/prelude#go
          # (imports flakeModules.go + go-overlay; not part of default)
        };
      };
    };
}
