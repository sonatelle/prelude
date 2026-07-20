# Go language pack via purpleclay/go-overlay.
#
# enable → contributions.go with the latest stable Go toolchain.
# Version selection and extra tools land in later commits.
{inputs}: {lib, ...}: {
  perSystem = {
    config,
    system,
    ...
  }: let
    cfg = config.prelude.languages.go;

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.go-overlay.overlays.default];
    };

    go = pkgs.go-bin.latestStable;
  in {
    options.prelude.languages.go = {
      enable = lib.mkEnableOption "Go language pack";
    };

    config = lib.mkIf (config.prelude.enable && cfg.enable) {
      prelude.contributions.go = {
        packages = [go];
      };
    };
  };
}
