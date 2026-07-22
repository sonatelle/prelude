# Rust language pack via oxalica/rust-overlay.
#
# Import via flakeModules.rust (not flakeModules.default). The project flake
# must declare input `rust-overlay` (convention; no function args). That input
# is required as soon as this module is imported, even if
# languages.rust.enable = false.
#
# version:
#   - "stable" | "beta" | "nightly" → that channel's latest default profile
#   - "1.xx.y" → rust-bin.stable."1.xx.y".default (stable only)
#   - "nightly-YYYY-MM-DD" | "beta-YYYY-MM-DD" → date pin on that channel
#   - "toolchain" → fromRustupToolchainFile toolchainFile (no extensions merge)
#
# tools.enable adds rust-src + rust-analyzer on channel/pin toolchains.
# package overrides everything as-is.
#
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

  # Parse pin specs (not bare channel names).
  # Returns null or { channel = "stable"|"beta"|"nightly"; pin = str; }
  parseVersionSpec = version: let
    # bare 1.xx.y → stable pin only
    mSemver =
      builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+)" version;
    # nightly-YYYY-MM-DD | beta-YYYY-MM-DD
    mChannelDate =
      builtins.match "(nightly|beta)-([0-9]{4}-[0-9]{2}-[0-9]{2})" version;
  in
    if mSemver != null
    then {
      channel = "stable";
      pin = builtins.elemAt mSemver 0;
    }
    else if mChannelDate != null
    then {
      channel = builtins.elemAt mChannelDate 0;
      pin = builtins.elemAt mChannelDate 1;
    }
    else null;
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

    # Channel latest (lazy). Nightly uses selectLatestNightlyWith.
    channelLatest = {
      stable = rustBin.stable.latest.default;
      beta = rustBin.beta.latest.default;
      nightly = rustBin.selectLatestNightlyWith (toolchain: toolchain.default);
    };

    # rust-bin.<channel>.<pin>.default when the attr exists.
    channelPin = channel: pin: let
      set =
        if channel == "stable"
        then rustBin.stable
        else if channel == "beta"
        then rustBin.beta
        else if channel == "nightly"
        then rustBin.nightly
        else null;
    in
      if set != null && set ? ${pin}
      then set.${pin}.default
      else null;

    parsed = parseVersionSpec cfg.version;

    # Named channel latest, else pin form, else error.
    toolchainFromVersion =
      channelLatest.${
        cfg.version
      }
      or (
        if parsed == null
        then
          throw ''
            prelude.languages.rust: unrecognized version "${cfg.version}".

            Use:
              - "stable" | "beta" | "nightly" (channel latest)
              - "1.xx.y" (stable pin only)
              - "nightly-YYYY-MM-DD" | "beta-YYYY-MM-DD" (date pin)
              - "toolchain" with toolchainFile
              - or package = <toolchain>
          ''
        else let
          pinned = channelPin parsed.channel parsed.pin;
        in
          lib.throwIf (pinned == null) ''
            prelude.languages.rust: version "${cfg.version}" not found in
            rust-overlay (${parsed.channel} pin "${parsed.pin}").

            Tips:
              - stable: "1.78.0"
              - nightly date: "nightly-2025-01-15"
              - beta date: "beta-2025-01-15"
              - or version = "toolchain" with toolchainFile
          ''
          pinned
      );

    # Auto IDE components when tools.enable; merge with user extensions.
    mergedExtensions = lib.unique (
      (lib.optionals cfg.tools.enable [
        "rust-src"
        "rust-analyzer"
      ])
      ++ cfg.extensions
    );

    # Apply extensions/targets only for channel/pin toolchains (not package /
    # toolchain-file, which are used as-is).
    withExtras = base: let
      needOverride =
        mergedExtensions != [] || cfg.targets != [];
    in
      if needOverride
      then
        base.override {
          extensions = mergedExtensions;
          targets = cfg.targets;
        }
      else base;

    # package > toolchain file > version (+ extras).
    toolchain =
      if cfg.package != null
      then cfg.package
      else if cfg.version == "toolchain"
      then
        lib.throwIf (cfg.toolchainFile == null) ''
          prelude.languages.rust: version "toolchain" requires
          languages.rust.toolchainFile (e.g. toolchainFile = ./rust-toolchain.toml).
        ''
        (rustBin.fromRustupToolchainFile cfg.toolchainFile)
      else withExtras toolchainFromVersion;
  in {
    options.prelude.languages.rust = {
      enable = lib.mkEnableOption "Rust language pack";

      version = lib.mkOption {
        type = t.str;
        default = "stable";
        example = "1.78.0";
        description = ''
          Rust toolchain from rust-overlay (ignored when `package` is set):

          - `"stable"` / `"beta"` / `"nightly"` → that channel's latest
            default profile (nightly via `selectLatestNightlyWith`)
          - `"1.xx.y"` → stable pin only (`rust-bin.stable."1.xx.y".default`)
          - `"nightly-YYYY-MM-DD"` / `"beta-YYYY-MM-DD"` → date pin
          - `"toolchain"` → `fromRustupToolchainFile` using `toolchainFile`
            (file is authoritative; `extensions` / `targets` / `tools` are
            not applied on top)
        '';
      };

      toolchainFile = lib.mkOption {
        type = t.nullOr t.path;
        default = null;
        example = ./rust-toolchain.toml;
        description = ''
          Path to `rust-toolchain` or `rust-toolchain.toml`. Required when
          `version = "toolchain"`. Set from this project's flake
          (e.g. `toolchainFile = ./rust-toolchain.toml`).
        '';
      };

      package = langLib.mkPackageOption {
        description = ''
          Explicit Rust toolchain derivation. Overrides `version` /
          `toolchainFile` / `extensions` / `targets` / `tools` (used as-is).
        '';
      };

      extensions = lib.mkOption {
        type = t.listOf t.str;
        default = [];
        example = ["miri" "llvm-tools-preview"];
        description = ''
          Extra rust-overlay / rustup components, merged with defaults from
          `tools.enable`. Applied via toolchain `.override { extensions = … }`.
          Ignored when `package` is set or `version = "toolchain"`.
        '';
      };

      targets = lib.mkOption {
        type = t.listOf t.str;
        default = [];
        example = ["wasm32-unknown-unknown"];
        description = ''
          Extra target triples (additional `rust-std`). Applied via
          `.override { targets = … }`. Ignored when `package` is set or
          `version = "toolchain"`.
        '';
      };

      tools = {
        enable = langLib.mkToolsEnableOption {
          default = true;
          description = ''
            When true, add `rust-src` and `rust-analyzer` to `extensions`
            for channel/pin toolchains (default profile). When false, only
            user `extensions` / `targets` are applied. Ignored for
            `package` and `version = "toolchain"`.
          '';
        };
      };
    };

    config = langLib.mkLanguagePack {
      name = "rust";
      enabled = config.prelude.enable && cfg.enable;
      packages = [toolchain];
    };
  };
}
