{
  description = "Python project shell via Sonatelle Prelude";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    prelude.url = "github:sonatelle/prelude";
    # Share this project's nixpkgs with Prelude (and its nested devshell).
    prelude.inputs.nixpkgs.follows = "nixpkgs";
    prelude.inputs.flake-parts.follows = "flake-parts";

    # Required by flakeModules.python (not part of flakeModules.default).
    # Do not follows nixpkgs — binary cache is tied to the flake's pin.
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
  };

  # Optional: speed up CPython fetches from nixpkgs-python.
  nixConfig = {
    extra-substituters = "https://nixpkgs-python.cachix.org";
    extra-trusted-public-keys = "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.prelude.flakeModules.default
        inputs.prelude.flakeModules.python
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
          name = "python";

          languages.python = {
            enable = true;
            # version = "3.14";                    # default
            # version = "3.14.6";
            # version = "file"; versionFile = ./.python-version;
            # tools.enable = true;                 # default: uv, ruff, ty
          };
        };
      };
    };
}
