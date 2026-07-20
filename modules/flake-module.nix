# Public flake-parts module entry for Prelude.
# Import together with inputs.devshell.flakeModule in the consumer flake.
{
  imports = [
    ./prelude/default.nix
    ./prelude/base.nix
  ];
}
