# Go language pack — phase 1 stub.
#
# Proves the languages/go directory layout and enable → contributions.go
# wiring. No Go toolchain is installed yet (phase 2+).
{lib, ...}: {
  perSystem = {config, ...}: let
    cfg = config.prelude.languages.go;
  in {
    options.prelude.languages.go = {
      enable = lib.mkEnableOption "Go language pack (stub; no toolchain yet)";
    };

    config = lib.mkIf (config.prelude.enable && cfg.enable) {
      # Non-empty contribution so merge creates devshells.go and folds into
      # default. Env-only keeps this phase free of Go packages.
      prelude.contributions.go = {
        env = [
          {
            name = "PRELUDE_GO_STUB";
            value = "1";
          }
        ];
      };
    };
  };
}
