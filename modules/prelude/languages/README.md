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
language-private — do not force Go's `stable`/`mod` shape onto every pack.

## Consumer import

```nix
# Core shell only
imports = [ inputs.prelude.flakeModules.default ];

# Go project: declare input go-overlay, then import the Go module
inputs.go-overlay.url = "github:purpleclay/go-overlay";
inputs.go-overlay.inputs.nixpkgs.follows = "nixpkgs";

imports = [
  inputs.prelude.flakeModules.default
  inputs.prelude.flakeModules.go
];
```

Importing `flakeModules.go` always requires consumer input `go-overlay`,
even when `languages.go.enable = false`. If you do not want `go-overlay`
in the lock at all, do not import `flakeModules.go`.

## Packs

| Pack | flakeModules | Required consumer input | Status |
| --- | --- | --- | --- |
| Go | `flakeModules.go` | `go-overlay` | go-overlay; see options below |

### Go options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the go pack |
| `version` | `"stable"` | `"stable"`; `"latest"`; `"mod"`; exact e.g. `"1.22.3"` |
| `goMod` | `null` | Path to `go.mod` (required when `version = "mod"`) |
| `package` | `null` | Explicit toolchain (overrides `version`) |
| `tools.enable` | `true` | gopls, delve, gofumpt, govulncheck, golangci-lint |
| `tools.autoConfig` | `false` | Install pack `.golangci.yml` into `$PRJ_ROOT` **only if missing** |

```nix
prelude.languages.go = {
  enable = true;
  # version = "1.22.3";
  # version = "mod"; goMod = ./go.mod;
  # tools.enable = true;
  # tools.autoConfig = true;
};
```

### golangci config install (Go only)

When `tools.enable` and `tools.autoConfig` are both true, shell startup
copies `languages/go/.golangci.yml` to `$PRJ_ROOT/.golangci.yml` **only
if** neither `.golangci.yml` nor `.golangci.yaml` exists there.

## Adding a pack

1. Create `languages/<name>/default.nix` (use `../lib` helpers).
2. Export `flakeModules.<name>` from the root `flake.nix`. Document the
   required consumer input name (e.g. Go expects `inputs.go-overlay`).
3. Optionally add `templates/<name>/` that imports default + the language module.
4. Document options in this README.

Do **not** add language modules to `flakeModules.default`.
