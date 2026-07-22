# Rust language pack via oxalica/rust-overlay.
#
# Import via flakeModules.rust (not flakeModules.default). The project flake
# must declare input `rust-overlay` (convention; no function args). That input
# is required as soon as this module is imported, even if
# languages.rust.enable = false.
#
# This step: stable toolchain (default). Further version / tools land later.
# Invalid config uses lib.throwIf (flake-parts has no perSystem.assertions).
{
  lib,
  inputs,
  ...
}: let
  langLib = import ../lib {inherit lib;};
  t = lib.types;

  rust-overlay =
    lib.throwIf (!(inputs ? rust-overlay)) ''
      prelude.languages.rust: missing flake input "rust-overlay".

      In this project's flake.nix, under inputs, add:

        rust-overlay.url = "github:oxalica/rust-overlay";
        rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

      Import flakeModules.default and flakeModules.rust.
      See modules/prelude/languages/README.md.
    ''
    inputs.rust-overlay;
in {
  perSystem = {
    config,
    system,
    ...
  }: let
    cfg = config.prelude.languages.rust;

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [rust-overlay.overlays.default];
    };

    rustBin = pkgs.rust-bin;

    # package > version. Only "stable" is wired here; more aliases next step.
    toolchain =
      if cfg.package != null
      then cfg.package
      else
        lib.throwIf (cfg.version != "stable") ''
          prelude.languages.rust: version "${cfg.version}" is not supported yet.
          Use default "stable", or set package to an explicit toolchain.
        ''
        rustBin.stable.latest.default;
  in {
    options.prelude.languages.rust = {
      enable = lib.mkEnableOption "Rust language pack";

      version = lib.mkOption {
        type = t.str;
        default = "stable";
        example = "stable";
        description = ''
          Rust toolchain selection (rust-overlay). Currently only
          `"stable"` is implemented (`rust-bin.stable.latest.default`).
          Ignored when `package` is set.
        '';
      };

      package = langLib.mkPackageOption {
        description = ''
          Explicit Rust toolchain derivation. Overrides `version`.
        '';
      };
    };

    config = langLib.mkLanguagePack {
      name = "rust";
      enabled = config.prelude.enable && cfg.enable;
      packages = [toolchain];
    };
  };
}
