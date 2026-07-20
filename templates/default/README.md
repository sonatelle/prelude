# Project shell (Prelude)

A quiet entry into the project environment.

This template uses
[Sonatelle Prelude](https://github.com/sonatelle/prelude) with
[numtide/devshell](https://github.com/numtide/devshell) and direnv.

## Setup

1. Install [Nix](https://nixos.org/download/) with flakes enabled.
2. Install [direnv](https://direnv.net/) (and ideally
   [nix-direnv](https://github.com/nix-community/nix-direnv)).
3. Edit `flake.nix` and set `prelude.packages` / `env` / `commands` as
   needed.
4. Run:

```bash
direnv allow
# or: nix develop
```

Both `inputs.devshell.flakeModule` and
`inputs.prelude.flakeModules.default` must stay in `imports`.
