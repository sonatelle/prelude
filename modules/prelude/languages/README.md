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
writes `config.prelude.contributions.<name>`.

Import packs from the root flake `preludeModule` (pass `{ inherit inputs; }`
when the pack needs flake inputs / overlays).

## Packs

| Pack | Path | Status |
| --- | --- | --- |
| Go | `languages/go/` | go-overlay; see options below |

### Go options

| Option | Default | Meaning |
| --- | --- | --- |
| `enable` | `false` | Turn on the go contribution |
| `version` | `null` | unset → latest stable; `"latest"`; `"mod"`; exact e.g. `"1.22.3"` |
| `goMod` | `null` | Path to `go.mod` (required when `version = "mod"`) |
| `package` | `null` | Explicit toolchain (overrides `version`) |
| `tools.enable` | `true` | gopls, delve, gofumpt, govulncheck, golangci-lint; syncs pack `.golangci.yml` → `$PRJ_ROOT` |

```nix
prelude.languages.go = {
  enable = true;
  # version = "1.22.3";
  # version = "mod"; goMod = ./go.mod;
  # tools.enable = true;   # default; set false for bare go only
};
```

With `tools.enable = true`, shell startup copies `languages/go/.golangci.yml`
to `$PRJ_ROOT/.golangci.yml` (updates when the pack file changes). The pack
is the source of truth while tools are enabled.

## Adding a pack

1. Create `languages/<name>/default.nix`.
2. Import it from the root `flake.nix` `preludeModule`.
3. Grow the pack with toolchains and tools as needed.
