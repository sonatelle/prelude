# Shared helpers for language packs (thin; no unified version semantics).
#
# Language modules keep their own version/channel/toolchain options and call
# these helpers for package override, tools.enable, pack wiring, and optional
# version-table resolution (Go / Rust / Node-style).
{lib}: let
  inherit (lib) mkOption mkIf types throwIf;
in {
  # Explicit toolchain override option shared by most language packs.
  mkPackageOption = {description ? "Explicit toolchain derivation. Overrides version selection."}:
    mkOption {
      type = types.nullOr types.package;
      default = null;
      inherit description;
    };

  # Boolean switch for attaching language tools (LSP, formatters, …).
  mkToolsEnableOption = {
    default ? true,
    description ? "When true, attach the language pack's default tools.",
  }:
    mkOption {
      type = types.bool;
      inherit default description;
    };

  # Write prelude.pack.<name> when the language pack is enabled.
  mkLanguagePack = {
    name,
    enabled,
    packages ? [],
    env ? [],
    commands ? [],
    startup ? {},
  }:
    mkIf enabled {
      prelude.pack.${name} = {
        inherit packages env commands startup;
      };
    };

  # Resolve package > named aliases > exact version table.
  # aliases values are lazy (e.g. fromGoMod only forced when version = "file").
  resolveByVersion = {
    package,
    version,
    aliases,
    hasVersion,
    versions,
    unknownMsg,
  }: let
    versionKnown =
      package != null || aliases ? ${version} || hasVersion version;
  in
    throwIf (!versionKnown) unknownMsg (
      if package != null
      then package
      else aliases.${version} or versions.${version}
    );
}
