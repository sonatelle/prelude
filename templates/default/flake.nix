{
  description = "Project development shell via Sonatelle Prelude";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    prelude.url = "github:sonatelle/prelude";
    # One follows line: share the consumer nixpkgs with Prelude (and its
    # nested devshell, which already follows Prelude's nixpkgs).
    prelude.inputs.nixpkgs.follows = "nixpkgs";
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

      perSystem = {pkgs, ...}: {
        prelude = {
          enable = true;
          name = "dev";
          packages = [
            # Add project tools here, e.g. pkgs.jq
          ];
          # env = [ { name = "EXAMPLE"; value = "1"; } ];
          # commands = [ { name = "hello"; help = "say hi"; command = "echo hi"; } ];
          # Later, when language packs exist:
          # languages.rust.enable = true;
        };
      };
    };
}
