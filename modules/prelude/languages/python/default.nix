# Python language pack via cachix/nixpkgs-python.
#
# Import via flakeModules.python (not flakeModules.default). The project flake
# must declare input `nixpkgs-python` (convention; no function args). That input
# is required as soon as this module is imported, even if
# languages.python.enable = false.
#
# version:
#   - "3.xx" → packages."3.xx" (latest formal patch for that minor)
#   - "3.xx.y" → exact release
#   - "file" → first line of versionFile (e.g. .python-version)
# nixpkgs-python only ships formal releases (no pre-release attrs).
#
# tools.enable adds uv, ruff, and ty from the project's nixpkgs.
# package overrides the interpreter as-is.
#
# Invalid config uses lib.throwIf (flake-parts has no perSystem.assertions).
{
  lib,
  inputs,
  ...
}: let
  langLib = import ../lib {inherit lib;};
  t = lib.types;

  nixpkgs-python =
    lib.throwIf (!(inputs ? nixpkgs-python)) ''
      prelude.languages.python: missing flake input "nixpkgs-python".

      In this project's flake.nix, under inputs, add:

        nixpkgs-python.url = "github:cachix/nixpkgs-python";

      Do not set nixpkgs-python.inputs.nixpkgs.follows = "nixpkgs" if you
      want binary-cache hits (builds are tied to the flake's pinned nixpkgs).

      Import flakeModules.default and flakeModules.python.
      See modules/prelude/languages/README.md.
    ''
    inputs.nixpkgs-python;

  # First non-empty line of a pyenv-style .python-version file.
  readVersionFile = path: let
    raw = builtins.readFile path;
    lines = lib.splitString "\n" (builtins.replaceStrings ["\r"] [""] raw);
    nonEmpty = builtins.filter (s: s != "") lines;
  in
    lib.throwIf (nonEmpty == []) ''
      prelude.languages.python: versionFile ${toString path} is empty
      (expected a version on the first line, e.g. 3.13 or 3.13.14).
    ''
    (lib.head nonEmpty);
in {
  perSystem = {
    config,
    system,
    ...
  }: let
    cfg = config.prelude.languages.python;

    # Tools from the project nixpkgs (not the interpreter flake's pin).
    pkgs = import inputs.nixpkgs {inherit system;};

    pySet =
      lib.throwIf (!(nixpkgs-python.packages ? ${system})) ''
        prelude.languages.python: nixpkgs-python has no packages for
        system "${system}".
      ''
      nixpkgs-python.packages.${system};

    versionKey =
      if cfg.version == "file"
      then
        lib.throwIf (cfg.versionFile == null) ''
          prelude.languages.python: version "file" requires
          languages.python.versionFile (e.g. versionFile = ./.python-version).
        ''
        (readVersionFile cfg.versionFile)
      else cfg.version;

    python =
      if cfg.package != null
      then cfg.package
      else
        lib.throwIf (!(pySet ? ${versionKey})) ''
          prelude.languages.python: version "${versionKey}" is not available
          in nixpkgs-python.

          Use:
            - a minor version (e.g. "3.13") → latest formal patch for that minor
            - an exact release (e.g. "3.13.14")
            - version = "file" with versionFile
            - or package = <interpreter>

          Pre-release tags are not provided by nixpkgs-python.
        ''
        pySet.${versionKey};

    tools = lib.optionals cfg.tools.enable [
      pkgs.uv
      pkgs.ruff
      pkgs.ty
    ];

    pythonBin = "${python}/bin/python";
  in {
    options.prelude.languages.python = {
      enable = lib.mkEnableOption "Python language pack";

      version = lib.mkOption {
        type = t.str;
        default = "3.13";
        example = "3.13.14";
        description = ''
          CPython version from nixpkgs-python (ignored when `package` is set):

          - minor string (e.g. `"3.13"`) → latest formal patch for that minor
          - exact release (e.g. `"3.13.14"`)
          - `"file"` → first line of `versionFile` (e.g. `.python-version`)

          There is no channel named stable/latest. Pre-releases are not
          available from nixpkgs-python.
        '';
      };

      versionFile = lib.mkOption {
        type = t.nullOr t.path;
        default = null;
        example = ./.python-version;
        description = ''
          Path to a pyenv-style version file. Required when
          `version = "file"`. Set from this project's flake
          (e.g. `versionFile = ./.python-version`).
        '';
      };

      package = langLib.mkPackageOption {
        description = ''
          Explicit Python interpreter derivation. Overrides `version` /
          `versionFile` (used as-is).
        '';
      };

      tools = {
        enable = langLib.mkToolsEnableOption {
          default = true;
          description = ''
            When true, add uv (package manager), ruff (lint/format), and ty
            (type checker and language server) from the project's nixpkgs.
          '';
        };
      };
    };

    config = langLib.mkLanguagePack {
      name = "python";
      enabled = config.prelude.enable && cfg.enable;
      packages = [python] ++ tools;
      env = [
        {
          name = "UV_PYTHON";
          value = pythonBin;
        }
        {
          name = "UV_PYTHON_PREFERENCE";
          value = "only-system";
        }
      ];
    };
  };
}
