# Minimal base contribution. Empty by default so Prelude stays thin.
# Consumers may fill prelude.base.packages or leave base disabled.
{lib, ...}: {
  perSystem = {config, ...}: let
    cfg = config.prelude;
  in {
    config = lib.mkIf (cfg.enable && cfg.base.enable) {
      prelude.contributions.base = {
        packages = cfg.base.packages;
        env = cfg.base.env;
        commands = cfg.base.commands;
      };
    };
  };
}
