# Prelude — Agent Guide

Project rules for agents. Sonatelle root `AGENTS.md` still applies (brand,
commit-message approval). **This file wins on Prelude architecture and
pre-commit.**

## Scope

- flake-parts + devshell module library — **thin** shells, not an app monorepo.
- Public API: `flakeModules.default` (core only), optional
  `flakeModules.<lang>`, `templates.*`.
- Do **not**: force languages into default, put language overlays on the
  root flake, auto-scan `languages/*`, or expose toolchains for `packages.*`
  unless asked.

## Layout (short)

```text
modules/prelude/          # options, pack merge → devshells
modules/prelude/languages/
  lib/                    # shared helpers
  <lang>/                 # one directory per language
templates/  examples/     # init + CI smoke
test/                     # gitignored playground only
```

## Architecture

| Export | Role |
| --- | --- |
| `flakeModules.default` | devshell + prelude core + base — **no languages** |
| `flakeModules.<lang>` | one pack; plain module; reads a **fixed project input name** |

- Language packs write `prelude.pack.<name>` when enabled; project flakes
  may also set `prelude.pack.*` ad hoc.
- Contract details: `modules/prelude/languages/README.md`.
- Use `languages/lib` (`mkLanguagePack`, `mkPackageOption`,
  `mkToolsEnableOption`, `resolveByVersion`). Version/channel semantics
  stay language-private.
- Validate with `lib.throwIf`. Errors: `prelude.languages.<name>: …`.
- Importing `flakeModules.<lang>` requires the fixed project input
  (e.g. `go-overlay`) even when `languages.<lang>.enable = false`.
  `enable = false` only skips installing the toolchain into the shell.
- Follows: root keeps `devshell`→`nixpkgs`; project flakes set
  `prelude`→`nixpkgs` / `flake-parts`. Systems: x86_64-linux,
  aarch64-linux, aarch64-darwin only.

**Language project patterns:**

```nix
# Go
inputs.go-overlay.url = "github:purpleclay/go-overlay";
inputs.go-overlay.inputs.nixpkgs.follows = "nixpkgs";
imports = [
  inputs.prelude.flakeModules.default
  inputs.prelude.flakeModules.go
];

# Rust
inputs.rust-overlay.url = "github:oxalica/rust-overlay";
inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
imports = [
  inputs.prelude.flakeModules.default
  inputs.prelude.flakeModules.rust
];
```

Wording for docs and errors: **project flake** / **this project's
flake.nix** / `inputs.…` examples — not “consumer”.

## Pre-commit (required)

Dogfood uses **[git-hooks.nix](https://github.com/cachix/git-hooks.nix)**
(only on this repo’s root flake — **not** in `flakeModules.default`).

The runner is still the **`pre-commit` CLI**, but it comes from the Nix
dogfood shell / store. **No system-wide or pip install.**

Hooks: `alejandra` (may write), `statix`, `deadnix`, `nil`.
Config: `statix.toml`. Generated `.pre-commit-config.yaml` is gitignored.

### Before every commit

```bash
# Format (writes; same formatter as flake `formatter`)
nix fmt .

# Run all hooks (uses store pre-commit; no global install)
nix develop -c pre-commit run -a

nix develop -c true
nix flake check -L --show-trace --no-write-lock-file
```

`nix develop` also installs the git hook via devshell startup. After that,
plain `git commit` runs the same suite (still using the Nix-managed
`pre-commit`, not a user-installed one).

If templates / language packs / module API / examples changed, also:

```bash
nix flake check path:./templates/default \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./templates/go \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./templates/rust \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./examples/minimal \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file
```

Report results; fix by hand; show commit message; wait for approval; commit.

Conventional Commits; small single-intent commits; `refactor!` on public
import breaks.

## Adding a language

1. `languages/<name>/default.nix` via `../lib` + fixed project input name.
2. `flakeModules.<name> = ./modules/prelude/languages/<name>;` (not in default).
3. Optional template; update `languages/README.md` + CI/pre-commit list.

## Notes

- Public docs: short calm English (Sonatelle tone).
- `test/` is gitignored. Path-based playground flakes need
  staged/committed prelude changes to see them.
- Prefer matching the Go pack over inventing a second style.
