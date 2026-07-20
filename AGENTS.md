# Prelude agent notes

- Prelude is a **flake-parts module library**, not a monorepo host for
  app code.
- Always keep `inputs.devshell.flakeModule` required and documented for
  consumers.
- Dogfood via local `./modules/flake-module.nix` import; export the same
  path as `flakeModules.default`.
- Keep the framework thin: no forced language toolchains in the default
  path.
- Prefer small, reviewable commits; Conventional Commits
  (`feat`, `fix`, `docs`, `chore`).
- Verify with `nix flake show`, `nix develop -c true`, and the
  `examples/minimal` flake when touching the module API.
- Keep `templates/default` aligned with the consumer recipe in README
  (dual import of devshell + prelude modules).
