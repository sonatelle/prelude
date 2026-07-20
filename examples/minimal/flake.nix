{
  description = "Minimal consumer of Sonatelle Prelude (path input for local checks)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    # Path input points at this repository root for local smoke tests.
    prelude.url = "path:../..";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.devshell.flakeModule
        inputs.prelude.flakeModules.default
      ];

      # nixos-unstable no longer supports x86_64-darwin (dropped in 26.11).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = {pkgs, ...}: {
        prelude = {
          enable = true;
          name = "minimal";
          packages = [pkgs.hello];
          commands = [
            {
              name = "greet";
              help = "Run GNU hello";
              command = "hello";
            }
          ];
        };
      };
    };
}
