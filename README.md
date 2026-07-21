# Prelude

An opening before the work begins.

Prelude takes its name from the *prelude*, a short piece that prepares
what follows without claiming the full form. That temperament fits this
repository: a thin place to enter a project carefully, not a platform
that tries to hold every language or workflow.

Prelude is a [flake-parts](https://flake.parts) module for development
shells. It sits on [numtide/devshell](https://github.com/numtide/devshell):
a short `prelude = { ... }` block fills `devshells.default` (and optional
named shells). Pair it with [direnv](https://direnv.net/) for automatic
environments.

Optional **language packs** (for example Go) plug in under
`prelude.languages.*` without changing the consumer import pattern.
Details live in `modules/prelude/languages/README.md`.

## Quick start

### New project from template

```bash
# Minimal shell
nix flake init -t github:sonatelle/prelude

# Go language pack (toolchain + default tools)
nix flake init -t github:sonatelle/prelude#go

direnv allow   # or: nix develop
```

### Existing flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    prelude.url = "github:sonatelle/prelude";
    # Share one nixpkgs with Prelude (and its nested devshell).
    prelude.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.prelude.flakeModules.default
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          prelude = {
            enable = true;
            name = "myproject";
            packages = [ pkgs.jq ];
            env = [
              { name = "MY_LOG"; value = "info"; }
            ];
            commands = [
              {
                name = "hello";
                help = "sanity check";
                command = "echo ready";
              }
            ];
          };
        };
    };
}
```

```bash
# .envrc
use flake
```

`flakeModules.default` already imports numtide/devshell. Prefer
`flake-parts.inputs.nixpkgs-lib.follows` and
`prelude.inputs.nixpkgs.follows` so the lock shares one nixpkgs tree.

### Go language pack

```nix
prelude = {
  enable = true;
  languages.go = {
    enable = true;
    # version = "stable";           # default
    # version = "mod"; goMod = ./go.mod;
    # tools.enable = true;          # default: gopls, delve, gofumpt, …
    # tools.autoConfig = false;     # set true to bootstrap .golangci.yml if missing
  };
};
```

Or start from the template: `nix flake init -t github:sonatelle/prelude#go`.
See `modules/prelude/languages/README.md`.

## How it works with devshell

- **Prelude** — options under `perSystem.prelude`; merges packs;
  writes `devshells.*`; re-exports `devshell.flakeModule`
- **devshell** — implements `devshells.*` and exports flake
  `devShells.*`
- **direnv** — loads `devShells.default` on `cd` via `use flake`

Prefer `prelude.*` for the default shell. Extra shells can still use raw
`devshells.<name>` when needed.

### Packs and named shells

```nix
prelude = {
  packages = [ pkgs.jq ];  # default shell only
  pack.tools = {
    packages = [ pkgs.hello ];
  };
};
```

- `nix develop` / direnv → **default** = all packs plus
  `packages` / `env` / `commands`
- `nix develop .#tools` → only the `tools` pack

Language modules write into `prelude.pack.<lang>` the same way.

## Layout

```text
modules/flake-module.nix          # public import body
modules/prelude/                  # options + merge + thin base
modules/prelude/languages/<name>/ # optional language packs
templates/default/                # nix flake init (minimal)
templates/go/                     # nix flake init -t …#go
examples/minimal/                 # path-based consumer smoke test
```

## Adding a language pack

See `modules/prelude/languages/README.md`. Sketch:

1. Add `modules/prelude/languages/<name>/` that sets
   `prelude.pack.<name>` when
   `prelude.languages.<name>.enable` is true.
2. Import it from the root `flake.nix` `preludeModule`.
3. Consumers enable it with a few lines under `prelude.languages`.
4. Optionally add `templates/<name>/` and export `templates.<name>`.

## Local checks

```bash
nix flake show
nix develop -c true
nix flake check -L --show-trace --no-write-lock-file

# Templates pin github:sonatelle/prelude; override to this tree while developing.
nix flake check path:./templates/default \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./templates/go \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./examples/minimal \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file
cd examples/minimal && nix develop -c greet
```

CI runs the same root, template, and example checks on
`ubuntu-latest` for pull requests and pushes to `main`.

## License

MIT
