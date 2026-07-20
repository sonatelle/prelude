# Prelude options and wiring body.
# Public consumers should import flakeModules.default from the root flake,
# which also re-exports numtide/devshell.
{
  imports = [
    ./prelude/default.nix
    ./prelude/base.nix
  ];
}
