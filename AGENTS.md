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
- Prefer small, reviewable commits; Conventional Commits
  (`feat`, `fix`, `docs`, `chore`).
- Verify with `nix flake show`, `nix develop -c true`, and the
  `examples/minimal` flake when touching the module API.
