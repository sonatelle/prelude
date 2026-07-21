# Shared option types for Prelude packs and shell wiring.
{lib}: let
  inherit (lib) types mkOption;
in {
  # One named pack (language module or advanced extension).
  # Each pack is merged into devshells.default and also
  # exposed as devshells.<name> when a non-empty name is used.
  packType = types.submodule {
    options = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Packages to add to this pack's shell.";
      };

      env = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = ''
          Environment variables in numtide/devshell form, e.g.
          `{ name = "FOO"; value = "bar"; }`.
        '';
      };

      commands = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = ''
          Custom commands in numtide/devshell form, e.g.
          `{ name = "hello"; help = "..."; command = "echo hi"; }`.
        '';
      };

      # numtide/devshell: devshell.startup.<name>.{ text, deps }
      startup = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            text = mkOption {
              type = types.str;
              description = "Script run when the shell starts.";
            };
            deps = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Other startup step names this step depends on.";
            };
          };
        });
        default = {};
        description = ''
          Startup hooks merged into `devshell.startup` for this pack
          (and into the default shell when packs are merged).
        '';
      };
    };
  };
}
