# Prelude

An opening before the work begins.

Prelude takes its name from the *prelude*, a short piece that prepares
what follows without claiming the full form. That temperament fits this
repository: a thin place to enter a project carefully, not a platform
that tries to hold every language or workflow.

Prelude is a [flake-parts](https://flake.parts) module for development
shells. It sits on [numtide/devshell](https://github.com/numtide/devshell):
a short `prelude = { ... }` block fills `devshells.default` (and optional
named shells). Pair it with [direnv](https://direnv.net/) for automatic
environments.

This repository is under construction. The scaffold provides a working
flake and CI; the module API, templates, and examples land in follow-up
work.

## Status

Scaffold only. Not yet a reusable consumer module.

## Local checks

```bash
nix flake show
nix develop -c true
nix develop -c statix check .
nix develop -c deadnix --fail .
```
