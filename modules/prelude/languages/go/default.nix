# Go language pack via purpleclay/go-overlay.
#
# enable → contributions.go with a selected Go toolchain.
{inputs}: {lib, ...}: {
  perSystem = {
    config,
    system,
    ...
  }: let
    cfg = config.prelude.languages.go;
    t = lib.types;

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.go-overlay.overlays.default];
    };

    goBin = pkgs.go-bin;

    # Resolve toolchain:
    #   package set            → use it
    #   version = null         → latestStable
    #   version = "latest"     → latest (may include RCs)
    #   version = "mod"        → fromGoMod goMod
    #   version = "1.22.3"     → versions."1.22.3"
    go =
      if cfg.package != null
      then cfg.package
      else if cfg.version == null
      then goBin.latestStable
      else if cfg.version == "mod"
      then
        if cfg.goMod == null
        then
          throw ''
            prelude.languages.go: version "mod" requires languages.go.goMod
            (path to the project's go.mod).
          ''
        else goBin.fromGoMod cfg.goMod
      else if cfg.version == "latest"
      then goBin.latest
      else if goBin.hasVersion cfg.version
      then goBin.versions.${cfg.version}
      else
        throw ''
          prelude.languages.go: Go version "${cfg.version}" is not available
          in go-overlay. Leave version unset for latest stable, or use
          "latest", "mod" (with goMod), an exact version, or package.
        '';
  in {
    options.prelude.languages.go = {
      enable = lib.mkEnableOption "Go language pack";

      version = lib.mkOption {
        type = t.nullOr t.str;
        default = null;
        example = "1.22.3";
        description = ''
          Go version from go-overlay:
          - unset / `null` (default) → latest stable
          - `"latest"` → latest release (may include RCs)
          - `"mod"` → `fromGoMod` using `goMod`
          - exact version string → that toolchain

          There is no `"latestStable"` value; that is the default when
          version is left unset. Ignored when `package` is set.
        '';
      };

      goMod = lib.mkOption {
        type = t.nullOr t.path;
        default = null;
        example = ./go.mod;
        description = ''
          Path to the project's `go.mod`. Required when `version = "mod"`.
        '';
      };

      package = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = ''
          Explicit Go derivation. Overrides `version` / `goMod`.
        '';
      };
    };

    config = lib.mkIf (config.prelude.enable && cfg.enable) {
      prelude.contributions.go = {
        packages = [go];
      };
    };
  };
}
