# Rust language pack (oxalica/rust-overlay in a later step).
#
# Import via flakeModules.rust (not flakeModules.default).
# Skeleton: enable + pack wiring only; toolchain comes next.
{lib, ...}: let
  langLib = import ../lib {inherit lib;};
in {
  perSystem = {config, ...}: let
    cfg = config.prelude.languages.rust;
  in {
    options.prelude.languages.rust = {
      enable = lib.mkEnableOption "Rust language pack";
    };

    config = langLib.mkLanguagePack {
      name = "rust";
      enabled = config.prelude.enable && cfg.enable;
      # packages filled when the toolchain step lands
      packages = [];
    };
  };
}
