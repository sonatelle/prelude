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

This is a framework release. Language packs can be added later without
changing the consumer import pattern.

## Quick start

### New project from template

```bash
nix flake init -t github:sonatelle/prelude
direnv allow   # or: nix develop
```

### Existing flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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

`flakeModules.default` already imports numtide/devshell. You only need
flake-parts, Prelude, and the single `nixpkgs` follows line above.

## How it works with devshell

- **Prelude** — options under `perSystem.prelude`; merges contributions;
  writes `devshells.*`; re-exports `devshell.flakeModule`
- **devshell** — implements `devshells.*` and exports flake
  `devShells.*`
- **direnv** — loads `devShells.default` on `cd` via `use flake`

Prefer `prelude.*` for the default shell. Extra shells can still use raw
`devshells.<name>` when needed.

### Contributions and named shells

```nix
prelude = {
  packages = [ pkgs.jq ];  # default shell only
  contributions.tools = {
    packages = [ pkgs.hello ];
  };
};
```

- `nix develop` / direnv → **default** = all contributions plus
  `packages` / `env` / `commands`
- `nix develop .#tools` → only the `tools` contribution

Language packs will write into `prelude.contributions.<lang>` the same
way.

## Layout

```text
modules/flake-module.nix     # public import body
modules/prelude/             # options + merge + thin base
templates/default/           # nix flake init template
examples/minimal/            # path-based consumer example
```

## Adding a language pack later

See `modules/prelude/languages/README.md`. Sketch:

1. Add `modules/prelude/languages/<name>.nix` that sets
   `prelude.contributions.<name>` when
   `prelude.languages.<name>.enable` is true.
2. Import it from `modules/flake-module.nix`.
3. Consumers enable it with a few lines under `prelude.languages`.

## Local checks

```bash
nix flake show
nix develop -c true
nix develop .#tools -c true
nix flake check -L --show-trace --no-write-lock-file
cd examples/minimal && nix develop -c greet
```

CI runs `nix flake check` on pull requests and pushes to `main`.

## License

MIT
