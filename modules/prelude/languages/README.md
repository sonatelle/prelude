# Language packs

Optional language modules for Prelude. **Not** included in
`flakeModules.default` — import `flakeModules.<lang>` per language.

## Layout

```text
languages/
  README.md
  lib/              # shared thin helpers
  <name>/
    default.nix     # pack module
    …               # optional assets (configs, etc.)
```

## Contract

Each pack:

1. Declares `options.prelude.languages.<name>.*`.
2. When enabled, writes `config.prelude.pack.<name>` (via `lib.mkLanguagePack`).
3. When `enable = false`, does not install the toolchain into the shell
   (`mkIf` / lazy). That is separate from flake inputs (see below).
4. Is exported as `flakeModules.<name>`, **not** merged into default.
5. Uses error prefix `prelude.languages.<name>: …`.
6. Language-specific flake inputs use a **fixed input name** (e.g. Go reads
   `inputs.go-overlay`); the module is not a function of those inputs.
   **Importing** `flakeModules.<lang>` requires that input to exist, even if
   `languages.<lang>.enable = false`. Only omit the language module (and
   its input) when the project does not use that language.

Shared helpers live in `lib/` (`mkPackageOption`, `mkToolsEnableOption`,
`mkLanguagePack`, `resolveByVersion`). Version/channel semantics stay
language-private — do not force Go's `stable`/`latest` shape onto every pack.

**File-based version (shared sentinel):** when a pack can read the version
from a project file, use `version = "file"`. The path option name and file
format stay language-private (`goMod`, `toolchainFile`, `versionFile`, …).
Do not invent per-language sentinels (`mod`, `toolchain`, `version-file`).

## Project import

```nix
# Core shell only
imports = [ inputs.prelude.flakeModules.default ];

# Language project: declare the pack input, then import the module
inputs.go-overlay.url = "github:purpleclay/go-overlay";
inputs.go-overlay.inputs.nixpkgs.follows = "nixpkgs";
# or: inputs.rust-overlay.url = "github:oxalica/rust-overlay";
#     inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
# or: inputs.nixpkgs-python.url = "github:cachix/nixpkgs-python";
#     # do not follows nixpkgs (binary cache is tied to the flake pin)

imports = [
  inputs.prelude.flakeModules.default
  inputs.prelude.flakeModules.go # or .rust / .python
];
```

Importing `flakeModules.<lang>` always requires that language's project
input (e.g. `go-overlay`, `rust-overlay`, `nixpkgs-python`), even when
`languages.<lang>.enable = false`. Omit the module (and its input) if
the project does not use that language.

## Packs

| Pack | flakeModules | Required project input | Status |
| --- | --- | --- | --- |
| Go | `flakeModules.go` | `go-overlay` | go-overlay; see options below |
| Rust | `flakeModules.rust` | `rust-overlay` | oxalica/rust-overlay; see below |
| Python | `flakeModules.python` | `nixpkgs-python` | cachix/nixpkgs-python; see below |

### Go options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the go pack |
| `version` | `"stable"` | `"stable"`; `"latest"`; `"file"`; exact e.g. `"1.22.3"` |
| `goMod` | `null` | Path to `go.mod` (required when `version = "file"`) |
| `package` | `null` | Explicit toolchain (overrides `version`) |
| `tools.enable` | `true` | gopls, delve, gofumpt, govulncheck, golangci-lint |
| `tools.autoConfig` | `false` | Install pack `.golangci.yml` into `$PRJ_ROOT` **only if missing** |

```nix
prelude.languages.go = {
  enable = true;
  # version = "1.22.3";
  # version = "file"; goMod = ./go.mod;
  # tools.enable = true;
  # tools.autoConfig = true;
};
```

### golangci config install (Go only)

When `tools.enable` and `tools.autoConfig` are both true, shell startup
copies `languages/go/.golangci.yml` to `$PRJ_ROOT/.golangci.yml` **only
if** neither `.golangci.yml` nor `.golangci.yaml` exists there.

### Rust options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the rust pack |
| `version` | `"stable"` | See version table below |
| `toolchainFile` | `null` | Path to `rust-toolchain` / `.toml` (for `version = "file"`) |
| `package` | `null` | Explicit toolchain (overrides version / tools / extensions) |
| `extensions` | `[]` | Extra components (merged with tools defaults) |
| `targets` | `[]` | Extra target triples (`rust-std`) |
| `tools.enable` | `true` | Add `rust-src` + `rust-analyzer` on channel/pin toolchains |

**`version` values:**

| Value | Result |
| --- | --- |
| `"stable"` / `"beta"` / `"nightly"` | Channel latest (default profile) |
| `"1.xx.y"` | Stable pin only |
| `"nightly-YYYY-MM-DD"` / `"beta-YYYY-MM-DD"` | Date pin |
| `"file"` | `fromRustupToolchainFile` (file is authoritative; no merge of `extensions` / `targets` / `tools`) |

```nix
prelude.languages.rust = {
  enable = true;
  # version = "stable";
  # version = "1.85.0";
  # version = "nightly-2025-06-01";
  # version = "file"; toolchainFile = ./rust-toolchain.toml;
  # extensions = [ "miri" ];
  # targets = [ "wasm32-unknown-unknown" ];
  # tools.enable = true;
};
```

`package` and `version = "file"` use the derivation/file **as-is**
(no automatic `rust-src` / `rust-analyzer` merge). Put components in the
toolchain file or the package when needed.

### Python options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the python pack |
| `version` | `"3.14"` | Minor (`"3.14"`), exact (`"3.14.6"`), or `"file"` |
| `versionFile` | `null` | Path to `.python-version` (required when `version = "file"`) |
| `package` | `null` | Explicit interpreter (overrides `version`) |
| `tools.enable` | `true` | uv, ruff, ty (from the project's nixpkgs) |

**`version` values:**

| Value | Result |
| --- | --- |
| `"3.xx"` | Latest formal patch for that minor in nixpkgs-python |
| `"3.xx.y"` | Exact formal release |
| `"file"` | First non-empty line of `versionFile` (pyenv-style) |

There is no channel named `stable` / `latest`. Pre-releases are **not**
available from nixpkgs-python (version numbers only).

When enabled, the pack sets `UV_PYTHON` to the selected interpreter and
`UV_PYTHON_PREFERENCE=only-system` so uv does not download its own CPython.

```nix
prelude.languages.python = {
  enable = true;
  # version = "3.14";
  # version = "3.14.6";
  # version = "file"; versionFile = ./.python-version;
  # tools.enable = true;  # uv, ruff, ty
};
```

Do **not** set `nixpkgs-python.inputs.nixpkgs.follows = "nixpkgs"` if you
want [nixpkgs-python.cachix.org](https://nixpkgs-python.cachix.org) hits;
cached builds are tied to that flake's pinned nixpkgs.

## Adding a pack

1. Create `languages/<name>/default.nix` (use `../lib` helpers).
2. Export `flakeModules.<name>` from the root `flake.nix`. Document the
   required project input name (e.g. Go expects `inputs.go-overlay`).
3. Optionally add `templates/<name>/` that imports default + the language
   module (see `templates/go`, `templates/rust`).
4. Document options in this README; extend CI template checks when adding
   a template.

Do **not** add language modules to `flakeModules.default`.
