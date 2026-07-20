# Go language pack.
#
# enable → contributions.go. Toolchain packages are added as the pack grows.
{lib, ...}: {
  perSystem = {config, ...}: let
    cfg = config.prelude.languages.go;
  in {
    options.prelude.languages.go = {
      enable = lib.mkEnableOption "Go language pack";
    };

    config = lib.mkIf (config.prelude.enable && cfg.enable) {
      # Non-empty contribution so merge creates devshells.go and folds into
      # default while packages are still empty.
      prelude.contributions.go = {
        env = [
          {
            name = "PRELUDE_GO";
            value = "1";
          }
        ];
      };
    };
  };
}
