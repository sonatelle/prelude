# Core Prelude options and wiring into numtide/devshell.
#
# Consumers set `perSystem.prelude = { ... }`. This module merges user
# packages with named packs and writes `devshells.default` plus
# one named shell per pack key (except the key "default").
#
# Requires numtide/devshell (re-exported by flakeModules.default).
{lib, ...}: let
  inherit
    (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mapAttrs
    filterAttrs
    attrValues
    concatLists
    ;
  types' = import ./types.nix {inherit lib;};
in {
  perSystem = {config, ...}: let
    cfg = config.prelude;

    packValues = attrValues cfg.pack;

    mergedPackages =
      concatLists (map (p: p.packages) packValues) ++ cfg.packages;

    mergedEnv = concatLists (map (p: p.env) packValues) ++ cfg.env;

    mergedCommands =
      concatLists (map (p: p.commands) packValues) ++ cfg.commands;

    # Later packs override same startup step names.
    mergedStartup =
      lib.foldl' (acc: p: acc // p.startup) {} packValues;

    defaultMotd =
      if cfg.motd != null
      then cfg.motd
      else "${cfg.name} development shell (Prelude)";

    # Named shells from packs: skip "default" and empty packs
    # (e.g. an empty base pack should not appear as nix develop .#base).
    packHasContent = p:
      p.packages != [] || p.env != [] || p.commands != [] || p.startup != {};

    namedShells =
      mapAttrs (name: p: {
        devshell = {
          inherit name;
          motd = "${name} shell (Prelude pack)";
          startup = p.startup;
        };
        inherit (p) packages env commands;
      }) (
        filterAttrs (
          n: p: n != "default" && packHasContent p
        )
        cfg.pack
      );

    defaultShell = {
      devshell = {
        inherit (cfg) name;
        motd = defaultMotd;
        startup = mergedStartup;
      };
      packages = mergedPackages;
      env = mergedEnv;
      commands = mergedCommands;
    };
  in {
    options.prelude = {
      enable =
        mkEnableOption "Prelude development shell wiring"
        // {
          default = true;
        };

      name = mkOption {
        type = types.str;
        default = "prelude";
        description = "Display name for the default development shell.";
      };

      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Extra packages added to the default shell only.";
      };

      env = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Extra environment variables for the default shell (devshell form).";
      };

      commands = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Extra custom commands for the default shell (devshell form).";
      };

      motd = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional message of the day for the default shell.
          When null, a short default motd is used.
        '';
      };

      base = {
        enable =
          mkEnableOption "Include the base pack in merge"
          // {
            default = true;
          };

        packages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Optional base packages shared via the base pack.";
        };

        env = mkOption {
          type = types.listOf types.attrs;
          default = [];
          description = "Optional base environment variables.";
        };

        commands = mkOption {
          type = types.listOf types.attrs;
          default = [];
          description = "Optional base commands.";
        };
      };

      # Named packs from language modules or advanced consumers.
      # Each key becomes devshells.<key> and is merged into default.
      pack = mkOption {
        type = types.attrsOf types'.packType;
        default = {};
        description = ''
          Named shell packs. Language modules write here when enabled.
          Each pack is merged into `devshells.default` and also exposed
          as `devshells.<name>` (except name `default`).
        '';
      };
    };

    # Language packs declare options under prelude.languages.<name> in
    # their own modules; this file intentionally leaves that path open.

    config = mkIf cfg.enable {
      # Writes into numtide/devshell's option space.
      devshells =
        namedShells
        // {
          default = defaultShell;
        };
    };
  };
}
