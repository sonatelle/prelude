# Python project shell (Prelude)

A quiet entry into a Python project environment.

This template uses
[Sonatelle Prelude](https://github.com/sonatelle/prelude) with the Python
language pack: `flakeModules.default` + `flakeModules.python`, plus project
input `nixpkgs-python` (read automatically). It only wires the shell — add
your own sources and project files in this directory.

## Setup

1. Install [Nix](https://nixos.org/download/) with flakes enabled.
2. Install [direnv](https://direnv.net/) (and ideally
   [nix-direnv](https://github.com/nix-community/nix-direnv)).
3. Create a project (or copy an existing tree here), for example:

```bash
uv init
# or: uv init --app
```

4. Optionally pin CPython from `.python-version` in `flake.nix`:

```nix
languages.python = {
  enable = true;
  version = "file";
  versionFile = ./.python-version;
};
```

5. Run:

```bash
direnv allow
# or: nix develop
python --version
uv --version
```

The template ships `.envrc` with `use flake` and `watch_file .python-version`
so direnv reloads when you use `version = "file"`.

On first evaluation Nix may ask to trust the `nixpkgs-python` substituter
from this flake's `nixConfig` (optional binary cache).

## Options

Under `prelude.languages.python` in `flake.nix`:

- `version` — `"3.13"` (default), another minor, an exact release, or `"file"`
- `versionFile` — path when `version = "file"` (e.g. `.python-version`)
- `tools.enable` — uv, ruff, ty (default true)

See Prelude `modules/prelude/languages/README.md` for the full option list.
