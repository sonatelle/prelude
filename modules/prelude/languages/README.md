# Language packs

This directory holds optional language modules for Prelude.

The framework release ships no language packs. To add one later:

1. Create `languages/<name>.nix` declaring `options.prelude.languages.<name>`
   and, when enabled, writing to `config.prelude.contributions.<name>`.
2. Import that file from `modules/flake-module.nix`.

Example sketch:

```nix
{ lib, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      cfg = config.prelude.languages.rust;
    in
    {
      options.prelude.languages.rust = {
        enable = lib.mkEnableOption "Rust toolchain";
      };

      config = lib.mkIf (config.prelude.enable && cfg.enable) {
        prelude.contributions.rust = {
          packages = [
            pkgs.rustc
            pkgs.cargo
            pkgs.rust-analyzer
            pkgs.clippy
            pkgs.rustfmt
          ];
        };
      };
    };
}
```
