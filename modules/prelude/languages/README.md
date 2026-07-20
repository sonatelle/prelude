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
| Go | `languages/go/` | **Stub** — `enable` only; no toolchain yet |

## Adding a pack

1. Create `languages/<name>/default.nix`.
2. Import it from the root `flake.nix` `preludeModule`.
3. Land real toolchains in follow-up commits; keep the first PR thin.
