# Go project shell (Prelude)

A quiet entry into a Go project environment.

This template uses
[Sonatelle Prelude](https://github.com/sonatelle/prelude) with the Go
language pack: `flakeModules.default` + `flakeModules.go`, plus project
input `go-overlay` (read automatically). It only wires the shell — add
your own Go sources and `go.mod` in this directory.

## Setup

1. Install [Nix](https://nixos.org/download/) with flakes enabled.
2. Install [direnv](https://direnv.net/) (and ideally
   [nix-direnv](https://github.com/nix-community/nix-direnv)).
3. Create a Go module (or copy an existing tree here), for example:

```bash
go mod init example.com/app
# add your packages / main.go as usual
```

4. Optionally pin the toolchain from `go.mod` in `flake.nix`:

```nix
languages.go = {
  enable = true;
  version = "file";
  goMod = ./go.mod;
};
```

5. Run:

```bash
direnv allow
# or: nix develop
go version
```

The template ships `.envrc` with `use flake` and `watch_file go.mod` so
direnv reloads when you change the module toolchain line under
`version = "file"`.

## Options

Under `prelude.languages.go` in `flake.nix`:

- `version` — `"stable"` (default), `"latest"`, `"file"`, or an exact version
- `goMod` — path to `go.mod` when `version = "file"`
- `tools.enable` — gopls, delve, gofumpt, govulncheck, golangci-lint
- `tools.autoConfig` — bootstrap pack `.golangci.yml` only if missing

See Prelude `modules/prelude/languages/README.md` for the full option list.
