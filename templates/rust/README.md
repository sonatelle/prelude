# Rust project shell (Prelude)

A quiet entry into a Rust project environment.

This template uses
[Sonatelle Prelude](https://github.com/sonatelle/prelude) with the Rust
language pack: `flakeModules.default` + `flakeModules.rust`, plus project
input `rust-overlay` (read automatically). It only wires the shell — add
your own crate sources in this directory.

## Setup

1. Install [Nix](https://nixos.org/download/) with flakes enabled.
2. Install [direnv](https://direnv.net/) (and ideally
   [nix-direnv](https://github.com/nix-community/nix-direnv)).
3. Create a crate (or copy an existing tree here), for example:

```bash
cargo init
# or: cargo new --lib .
```

4. Optionally pin the toolchain from a rustup file in `flake.nix`:

```nix
languages.rust = {
  enable = true;
  version = "file";
  toolchainFile = ./rust-toolchain.toml;
};
```

5. Run:

```bash
direnv allow
# or: nix develop
rustc --version
cargo --version
```

The template ships `.envrc` with `use flake` and `watch_file` for
`rust-toolchain.toml` / `rust-toolchain` so direnv reloads when you use
`version = "file"`.

## Options

Under `prelude.languages.rust` in `flake.nix`:

- `version` — `"stable"` (default), `"beta"`, `"nightly"`, `"1.xx.y"`,
  `"nightly-YYYY-MM-DD"`, `"beta-YYYY-MM-DD"`, or `"file"`
- `toolchainFile` — path when `version = "file"`
- `extensions` / `targets` — extra components and target triples
- `tools.enable` — add `rust-src` and `rust-analyzer` (default true)

See Prelude `modules/prelude/languages/README.md` for the full option list.
