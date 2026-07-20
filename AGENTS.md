# Prelude agent notes

- Prelude is a **flake-parts module library**, not a monorepo host for
  app code.
- Export `flakeModules.default` as a single attrset that imports both
  `inputs.devshell.flakeModule` and `./modules/flake-module.nix`.
  Dogfood that same attrset; do not maintain two import recipes.
- Keep `devshell.inputs.nixpkgs.follows = "nixpkgs"` in this flake.
- Consumer template should only need `prelude.inputs.nixpkgs.follows`
  (not a separate `devshell` input or multi-follows block).
- Keep the framework thin: no forced language toolchains in the default
  path.
- Language packs live under `modules/prelude/languages/<name>/` (directory
  per language). Import them from root `preludeModule`; keep early packs
  as thin stubs before toolchains.
- Prefer small, reviewable commits; Conventional Commits
  (`feat`, `fix`, `docs`, `chore`).
- Verify with `nix flake show`, `nix develop -c true`, the
  `examples/minimal` flake, and
  `nix flake check path:./templates/default --override-input prelude path:.`
  when touching the module API or template.
- CI uses `ubuntu-latest` and checks root, template, and minimal example
  flakes (template/example override `prelude` to `path:.`).
