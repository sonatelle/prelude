{
  description = "Prelude — reusable flake-parts module for project development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];

      # nixos-unstable no longer supports x86_64-darwin (dropped in 26.11).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          # Temporary root shell until the Prelude module lands.
          devshells.default = {
            devshell.name = "prelude";
            packages = [
              pkgs.nil
              pkgs.nixfmt
              pkgs.statix
              pkgs.deadnix
            ];
          };
        };
    };
}
