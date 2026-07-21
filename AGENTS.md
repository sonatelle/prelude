# Prelude agent notes

- Prelude is a **flake-parts module library**, not a monorepo host for
  app code.
- Export `flakeModules.default` as a single attrset that imports both
  `inputs.devshell.flakeModule` and `./modules/flake-module.nix`.
  Dogfood that same attrset; do not maintain two import recipes.
- Keep `devshell.inputs.nixpkgs.follows = "nixpkgs"` in this flake.
- Consumer template should use `prelude.inputs.nixpkgs.follows` and
  `prelude.inputs.flake-parts.follows` (not a separate `devshell` input).
- Keep the framework thin: no forced language toolchains in the default
  path.
- Language packs live under `modules/prelude/languages/<name>/` (directory
  per language). Import packs that need flake inputs from root
  `preludeModule` with `{ inherit inputs; }`.
- Keep `go-overlay.inputs.nixpkgs.follows = "nixpkgs"`.
- Prefer small, reviewable commits; Conventional Commits
  (`feat`, `fix`, `docs`, `chore`).
- Verify with `nix flake show`, `nix develop -c true`, the
  `examples/minimal` flake, and template checks
  (`templates/default`, `templates/go` with
  `--override-input prelude path:.`) when touching the module API,
  language packs, or templates.
- CI uses `ubuntu-latest` and checks root, default template, go template,
  and minimal example flakes (template/example override `prelude` to
  `path:.`).
