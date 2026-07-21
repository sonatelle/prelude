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
| `flakeModules.<lang>` | one pack; plain module; reads a **fixed consumer input name** |

- Language packs write `prelude.pack.<name>` when enabled; consumers may
  also set `prelude.pack.*` ad hoc.
- Contract details: `modules/prelude/languages/README.md`.
- Use `languages/lib` (`mkLanguagePack`, `mkPackageOption`,
  `mkToolsEnableOption`, `resolveByVersion`). Version/channel semantics
  stay language-private.
- Validate with `lib.throwIf`. Errors: `prelude.languages.<name>: …`.
- Importing `flakeModules.<lang>` requires the fixed consumer input
  (e.g. `go-overlay`) even when `languages.<lang>.enable = false`.
  `enable = false` only skips installing the toolchain into the shell.
- Follows: root keeps `devshell`→`nixpkgs`; consumers
  `prelude`→`nixpkgs` / `flake-parts`. Systems: x86_64-linux,
  aarch64-linux, aarch64-darwin only.

**Go consumer pattern:**

```nix
inputs.go-overlay.url = "github:purpleclay/go-overlay";
inputs.go-overlay.inputs.nixpkgs.follows = "nixpkgs";
imports = [
  inputs.prelude.flakeModules.default
  inputs.prelude.flakeModules.go
];
```

## Pre-commit (required)

Before **every** commit:

1. `nix fmt`
2. `nix develop -c true`
3. `nix flake check -L --show-trace --no-write-lock-file`
4. If templates / language packs / module API / examples changed, also:

```bash
nix flake check path:./templates/default \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./templates/go \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file

nix flake check path:./examples/minimal \
  --override-input prelude path:. \
  -L --show-trace --no-write-lock-file
```

5. Report what ran; fix failures before proposing the commit.
6. Show the commit message; wait for explicit approval; then commit.

Conventional Commits; small single-intent commits; `refactor!` on public
import breaks.

## Adding a language

1. `languages/<name>/default.nix` via `../lib` + fixed input name.
2. `flakeModules.<name> = ./modules/prelude/languages/<name>;` (not in default).
3. Optional template; update `languages/README.md` + CI/pre-commit list.

## Notes

- Public docs: short calm English (Sonatelle tone).
- `test/` is gitignored. Path consumers need staged/committed prelude
  changes to see them.
- Prefer matching the Go pack over inventing a second style.
