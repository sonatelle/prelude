# Shared option types for Prelude contributions and shell wiring.
{ lib }:
let
  inherit (lib) types mkOption;
in
{
  # One named contribution (language pack or advanced extension).
  # Each contribution is merged into devshells.default and also
  # exposed as devshells.<name> when non-empty name is used.
  contributionType = types.submodule {
    options = {
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Packages to add to this contribution's shell.";
      };

      env = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = ''
          Environment variables in numtide/devshell form, e.g.
          `{ name = "FOO"; value = "bar"; }`.
        '';
      };

      commands = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = ''
          Custom commands in numtide/devshell form, e.g.
          `{ name = "hello"; help = "..."; command = "echo hi"; }`.
        '';
      };
    };
  };
}
