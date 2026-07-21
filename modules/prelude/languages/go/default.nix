# Go language pack via purpleclay/go-overlay.
#
# Import via flakeModules.go (not flakeModules.default). Expects the consumer
# flake to declare an input named `go-overlay` (convention; no function args).
# enable → pack.go with a selected toolchain and optional tools.
# Invalid config uses lib.throwIf (flake-parts has no perSystem.assertions).
{
  lib,
  inputs,
  ...
}: let
  langLib = import ../lib {inherit lib;};
  t = lib.types;

  go-overlay = lib.throwIf (!(inputs ? go-overlay)) ''
    prelude.languages.go: flake input "go-overlay" is required.

    Add to the consumer flake:

      go-overlay.url = "github:purpleclay/go-overlay";
      go-overlay.inputs.nixpkgs.follows = "nixpkgs";

    Then import flakeModules.default and flakeModules.go.
  ''
  inputs.go-overlay;
in {
  perSystem = {
    config,
    system,
    ...
  }: let
    cfg = config.prelude.languages.go;

    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [go-overlay.overlays.default];
    };

    goBin = pkgs.go-bin;

    # Named aliases for version; exact versions fall through to goBin.versions.
    # Attr values are lazy — fromGoMod runs only when version = "mod".
    versionAliases = {
      stable = goBin.latestStable;
      latest = goBin.latest;
      mod = goBin.fromGoMod cfg.goMod;
    };

    # package > version.
    go =
      lib.throwIf (cfg.version == "mod" && cfg.goMod == null) ''
        prelude.languages.go: version "mod" requires languages.go.goMod
        (path to the project's go.mod), e.g. goMod = ./go.mod;
      ''
      (
        langLib.resolveByVersion {
          package = cfg.package;
          version = cfg.version;
          aliases = versionAliases;
          hasVersion = goBin.hasVersion;
          versions = goBin.versions;
          unknownMsg = ''
            prelude.languages.go: Go version "${cfg.version}" is not available
            in go-overlay. Use default "stable", "latest", "mod" (with goMod),
            an exact version, or package.
          '';
        }
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

    # Bootstrap only (Go-private). Never overwrite project-owned configs.
    golangciStartup = lib.optionalAttrs (cfg.tools.enable && cfg.tools.autoConfig) {
      go-golangci-config = {
        text = ''
          _src=${golangciConfig}
          _root="''${PRJ_ROOT}"
          _yml="''${_root}/.golangci.yml"
          _yaml="''${_root}/.golangci.yaml"
          if [[ -f "$_yml" || -f "$_yaml" ]]; then
            :
          else
            # Store path is 0444; project copy must be user-writable.
            cp "$_src" "$_yml"
            chmod u+w "$_yml" 2>/dev/null || true
          fi
        '';
      };
    };
  in {
    options.prelude.languages.go = {
      enable = lib.mkEnableOption "Go language pack";

      version = lib.mkOption {
        type = t.str;
        default = "stable";
        example = "1.22.3";
        description = ''
          Go version from go-overlay:
          - `"stable"` (default) → latest stable
          - `"latest"` → latest release (may include RCs)
          - `"mod"` → `fromGoMod` using `goMod` (set `goMod = ./go.mod`)
          - exact version string → that toolchain

          Ignored when `package` is set.
        '';
      };

      goMod = lib.mkOption {
        type = t.nullOr t.path;
        default = null;
        example = ./go.mod;
        description = ''
          Path to the project's `go.mod`. Required when `version = "mod"`.
          Must be set from the consumer flake (e.g. `goMod = ./go.mod`).
        '';
      };

      package = langLib.mkPackageOption {
        description = ''
          Explicit Go derivation. Overrides `version` / `goMod`.
          Must support `withTools` when `tools` is enabled.
        '';
      };

      tools = {
        enable = langLib.mkToolsEnableOption {
          default = true;
          description = ''
            When true, attach gopls, delve, gofumpt, govulncheck, and
            golangci-lint via go-overlay `withTools` (locked to the selected
            Go version). staticcheck is not listed separately; use
            golangci-lint for that class of checks.
          '';
        };

        autoConfig = lib.mkOption {
          type = t.bool;
          default = false;
          description = ''
            When true (and `tools.enable` is true), on shell entry install
            the pack's `.golangci.yml` into `$PRJ_ROOT` only if neither
            `.golangci.yml` nor `.golangci.yaml` is already present.
            Existing project configs are never overwritten.
          '';
        };
      };
    };

    config = langLib.mkLanguagePack {
      name = "go";
      enabled = config.prelude.enable && cfg.enable;
      packages = [toolchain];
      startup = golangciStartup;
    };
  };
}
