# Prelude agent notes

- Prelude is a **flake-parts module library**, not a monorepo host for
  app code.
- Export `flakeModules.default` as core only: `inputs.devshell.flakeModule`
  + `./modules/flake-module.nix`. **No language packs in default.**
- Language packs: `modules/prelude/languages/<name>/` plus helpers in
  `languages/lib/`. Export each as `flakeModules.<name>`. Language-specific
  flake inputs use a fixed name on the **consumer** flake (Go:
  `inputs.go-overlay`); do not pass them as module function args.
- Consumers import `flakeModules.default` and, when needed,
  `flakeModules.go` (after declaring `go-overlay`).
- Keep `devshell.inputs.nixpkgs.follows = "nixpkgs"` in this flake.
- Consumer templates should use `prelude.inputs.nixpkgs.follows` and
  `prelude.inputs.flake-parts.follows` (not a separate `devshell` input).
- Keep the framework thin: no forced language toolchains in the default
  path; do not put language overlays on the root flake unless required
  for dogfood (prefer templates to own go-overlay, rust-overlay, …).
- Prefer small, reviewable commits; Conventional Commits
  (`feat`, `fix`, `docs`, `chore`).
- Before creating any commit, show the proposed commit message and wait
  for explicit approval (Sonatelle root AGENTS.md).
- Verify with `nix flake show`, `nix develop -c true`, the
  `examples/minimal` flake, and template checks
  (`templates/default`, `templates/go` with
  `--override-input prelude path:.`) when touching the module API,
  language packs, or templates.
- CI uses `ubuntu-latest` and checks root, default template, go template,
  and minimal example flakes (template/example override `prelude` to
  `path:.`).
