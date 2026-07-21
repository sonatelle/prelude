# Language packs

Optional language modules for Prelude.

## Layout

Each language is a **directory** (never a lone `languages/<name>.nix`):

```text
languages/
  README.md
  <name>/
    default.nix     # pack module
    …               # optional assets (configs, etc.)
```

A pack declares `options.prelude.languages.<name>` and, when enabled,
writes `config.prelude.pack.<name>`.

Import packs from the root flake `preludeModule` (pass `{ inherit inputs; }`
when the pack needs flake inputs / overlays).

## Packs

| Pack | Path | Status |
| --- | --- | --- |
| Go | `languages/go/` | go-overlay; see options below |

### Go options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the go pack |
| `version` | `"stable"` | `"stable"`; `"latest"`; `"mod"`; exact e.g. `"1.22.3"` |
| `goMod` | `null` | Path to `go.mod` (required when `version = "mod"`, e.g. `./go.mod`) |
| `package` | `null` | Explicit toolchain (overrides `version`) |
| `tools.enable` | `true` | gopls, delve, gofumpt, govulncheck, golangci-lint |
| `tools.autoConfig` | `false` | If tools on: install pack `.golangci.yml` into `$PRJ_ROOT` **only if missing** |

```nix
prelude.languages.go = {
  enable = true;
  # version = "1.22.3";
  # version = "mod"; goMod = ./go.mod;
  # tools.enable = true;          # default
  # tools.autoConfig = true;      # default false; bootstrap .golangci.yml if missing
};
```

### golangci config install

When `tools.enable` and `tools.autoConfig` are both true, shell startup
copies `languages/go/.golangci.yml` to `$PRJ_ROOT/.golangci.yml` **only
if** neither `.golangci.yml` nor `.golangci.yaml` exists there.
Project-owned configs are never overwritten.

`$PRJ_ROOT` is the flake / direnv root (numtide/devshell). In a monorepo
where Go lives in a subdirectory, either place config at the root, leave
`tools.autoConfig = false`, or maintain your own config in the package dir.

Suggested workflow: keep a committed project `.golangci.yml` (or let
the first shell entry bootstrap one, then commit it).

## Adding a pack

1. Create `languages/<name>/default.nix`.
2. Import it from the root `flake.nix` `preludeModule`.
3. Grow the pack with toolchains and tools as needed.
