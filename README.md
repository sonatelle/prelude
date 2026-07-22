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

Optional **language packs** (for example Go) live under
`prelude.languages.*` and are imported **separately** via
`flakeModules.<lang>` so non-language projects stay thin.
Details live in `modules/prelude/languages/README.md`.

## Quick start

### New project from template

```bash
# Minimal shell
nix flake init -t github:sonatelle/prelude

# Go language pack (toolchain + default tools)
nix flake init -t github:sonatelle/prelude#go

# Rust language pack (toolchain + default tools)
nix flake init -t github:sonatelle/prelude#rust

# Python language pack (interpreter + default tools)
nix flake init -t github:sonatelle/prelude#python

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
    # Share one nixpkgs / flake-parts tree with Prelude.
    prelude.inputs.nixpkgs.follows = "nixpkgs";
    prelude.inputs.flake-parts.follows = "flake-parts";
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
`flake-parts.inputs.nixpkgs-lib.follows`,
`prelude.inputs.nixpkgs.follows`, and
`prelude.inputs.flake-parts.follows` so the lock shares one tree.

### Go language pack

`flakeModules.default` does **not** include Go. Declare a flake input named
`go-overlay`, then import `flakeModules.go` (it reads `inputs.go-overlay`).
That input is required whenever `flakeModules.go` is imported, even if
`languages.go.enable = false`:

```nix
{
  inputs = {
    # … nixpkgs, flake-parts, prelude follows …
    go-overlay.url = "github:purpleclay/go-overlay";
    go-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.prelude.flakeModules.default
        inputs.prelude.flakeModules.go
      ];

      perSystem = {
        prelude = {
          enable = true;
          languages.go = {
            enable = true;
            # version = "stable";
            # version = "file"; goMod = ./go.mod;
            # tools.enable = true;
            # tools.autoConfig = false;
          };
        };
      };
    };
}
```

Or: `nix flake init -t github:sonatelle/prelude#go`.
See `modules/prelude/languages/README.md`.

### Rust language pack

Same pattern with `rust-overlay` and `flakeModules.rust`:

```nix
{
  inputs = {
    # … nixpkgs, flake-parts, prelude follows …
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.prelude.flakeModules.default
        inputs.prelude.flakeModules.rust
      ];

      perSystem = {
        prelude = {
          enable = true;
          languages.rust = {
            enable = true;
            # version = "stable";
            # version = "1.85.0";
            # version = "nightly-2025-06-01";
            # version = "file"; toolchainFile = ./rust-toolchain.toml;
            # extensions = [ "miri" ];
            # targets = [ "wasm32-unknown-unknown" ];
            # tools.enable = true;  # rust-src + rust-analyzer
          };
        };
      };
    };
}
```

Or: `nix flake init -t github:sonatelle/prelude#rust`.
See `modules/prelude/languages/README.md` for the full option list.

### Python language pack

Same pattern with `nixpkgs-python` and `flakeModules.python`. Prefer
**not** following `nixpkgs` on that input if you want binary-cache hits:

```nix
{
  inputs = {
    # … nixpkgs, flake-parts, prelude follows …
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    # do not: nixpkgs-python.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.prelude.flakeModules.default
        inputs.prelude.flakeModules.python
      ];

      perSystem = {
        prelude = {
          enable = true;
          languages.python = {
            enable = true;
            # version = "3.14";
            # version = "3.14.6";
            # version = "file"; versionFile = ./.python-version;
            # tools.enable = true;  # uv, ruff, ty
          };
        };
      };
    };
}
```

Or: `nix flake init -t github:sonatelle/prelude#python`.
See `modules/prelude/languages/README.md` for the full option list.

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
modules/prelude/languages/lib/    # shared language-pack helpers
modules/prelude/languages/<name>/ # optional language packs
templates/default/                # nix flake init (minimal)
templates/go/                     # nix flake init -t …#go
templates/rust/                   # nix flake init -t …#rust
templates/python/                 # nix flake init -t …#python
examples/minimal/                 # path-based example for local checks
```

## Adding a language pack

See `modules/prelude/languages/README.md`. Sketch:

1. Add `modules/prelude/languages/<name>/` using `languages/lib`.
2. Export `flakeModules.<name>` from the root flake. Document the required
   project input name. Do **not** add the pack to `flakeModules.default`.
3. The project flake adds that input, imports `default` +
   `flakeModules.<name>`, and enables `prelude.languages.<name>`.
4. Optionally add `templates/<name>/`.

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

nix flake check path:./templates/rust \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./templates/python \
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
