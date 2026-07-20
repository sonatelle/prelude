# Shared option types for Prelude contributions and shell wiring.
{lib}: let
  inherit (lib) types mkOption;
in {
  # One named contribution (language pack or advanced extension).
  # Each contribution is merged into devshells.default and also
  # exposed as devshells.<name> when non-empty name is used.
  contributionType = types.submodule {
    options = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Packages to add to this contribution's shell.";
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
          Startup hooks merged into `devshell.startup` for this contribution
          (and into the default shell when contributions are merged).
        '';
      };
    };
  };
}
