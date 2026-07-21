# Go language pack via purpleclay/go-overlay.
#
# enable → pack.go with a selected toolchain and optional tools.
# Invalid config uses lib.throwIf (flake-parts has no perSystem.assertions).
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

    versionKnown =
      cfg.package != null
      || cfg.version == null
      || cfg.version == "latest"
      || cfg.version == "mod"
      || goBin.hasVersion cfg.version;

    # package > version. lib.throwIf keeps checks next to the value.
    go =
      lib.throwIf (cfg.version == "mod" && cfg.goMod == null) ''
        prelude.languages.go: version "mod" requires languages.go.goMod
        (path to the project's go.mod).
      ''
      (
        lib.throwIf (!versionKnown) ''
          prelude.languages.go: Go version "${toString cfg.version}" is not
          available in go-overlay. Leave version unset for latest stable, or
          use "latest", "mod" (with goMod), an exact version, or package.
        ''
        (
          if cfg.package != null
          then cfg.package
          else if cfg.version == null
          then goBin.latestStable
          else if cfg.version == "mod"
          then goBin.fromGoMod cfg.goMod
          else if cfg.version == "latest"
          then goBin.latest
          else goBin.versions.${cfg.version}
        )
      );

    # Fixed set when tools is enabled. staticcheck is omitted (covered by
    # golangci-lint). No free-form extra list.
    toolNames = lib.optionals cfg.tools.enable [
      "gopls"
      "delve"
      "gofumpt"
      "govulncheck"
      "golangci-lint"
    ];

    # Final derivation for the pack: bare go, or go + tools.
    toolchain =
      if toolNames == []
      then go
      else
        lib.throwIf (!(go ? withTools)) ''
          prelude.languages.go: tools require a go-overlay toolchain with
          withTools. Unset languages.go.package or pass a go-overlay derivation.
        ''
        (go.withTools toolNames);

    # Bundled linter config shipped next to this pack module.
    golangciConfig = ./.golangci.yml;

    # Sync pack config into the project root when tools are on. Pack is the
    # source of truth while tools.enable; disable tools to own the file.
    golangciStartup = lib.optionalAttrs cfg.tools.enable {
      go-golangci-config = {
        text = ''
          _src=${golangciConfig}
          _dst="''${PRJ_ROOT}/.golangci.yml"
          if [[ ! -f "$_dst" ]] || ! cmp -s "$_src" "$_dst"; then
            # Store path is 0444; project copy must be user-writable.
            cp "$_src" "$_dst"
          fi
          chmod u+w "$_dst" 2>/dev/null || true
        '';
      };
    };
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
          Must support `withTools` when `tools` is enabled.
        '';
      };

      tools = {
        enable = lib.mkOption {
          type = t.bool;
          default = true;
          description = ''
            When true, attach gopls, delve, gofumpt, govulncheck, and
            golangci-lint via go-overlay `withTools` (locked to the selected
            Go version). Also syncs the pack's `.golangci.yml` into
            `$PRJ_ROOT` on shell entry. staticcheck is not listed separately;
            use golangci-lint for that class of checks.
          '';
        };
      };
    };

    config = lib.mkIf (config.prelude.enable && cfg.enable) {
      prelude.pack.go = {
        packages = [toolchain];
        startup = golangciStartup;
      };
    };
  };
}
