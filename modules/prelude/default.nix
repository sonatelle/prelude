# Core Prelude options and wiring into numtide/devshell.
#
# Consumers set `perSystem.prelude = { ... }`. This module merges user
# packages with named contributions and writes `devshells.default` plus
# one named shell per contribution key (except the key "default").
#
# Requires `inputs.devshell.flakeModule` in the consumer's imports.
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

    contributionValues = attrValues cfg.contributions;

    mergedPackages =
      concatLists (map (c: c.packages) contributionValues) ++ cfg.packages;

    mergedEnv = concatLists (map (c: c.env) contributionValues) ++ cfg.env;

    mergedCommands =
      concatLists (map (c: c.commands) contributionValues) ++ cfg.commands;

    defaultMotd =
      if cfg.motd != null
      then cfg.motd
      else ''
        ${cfg.name} development shell (Prelude)
      '';

    # Named shells from contributions: skip "default" and empty contributions
    # (e.g. an empty base pack should not appear as nix develop .#base).
    contributionHasContent = c: c.packages != [] || c.env != [] || c.commands != [];

    namedShells =
      mapAttrs (name: c: {
        devshell = {
          inherit name;
          motd = "${name} shell (Prelude contribution)";
        };
        inherit (c) packages env commands;
      }) (
        filterAttrs (
          n: c: n != "default" && contributionHasContent c
        )
        cfg.contributions
      );

    defaultShell = {
      devshell = {
        inherit (cfg) name;
        motd = defaultMotd;
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
          mkEnableOption "Include the base contribution in merge"
          // {
            default = true;
          };

        packages = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Optional base packages shared via the base contribution.";
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

      # Named contributions from language packs or advanced consumers.
      # Each key becomes devshells.<key> and is merged into default.
      contributions = mkOption {
        type = types.attrsOf types'.contributionType;
        default = {};
        description = ''
          Named shell contributions. Language modules write here when
          enabled. Each contribution is merged into `devshells.default`
          and also exposed as `devshells.<name>` (except name `default`).
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
