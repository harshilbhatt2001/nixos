{ ... }: {
  # Per-project dev environments: `devenv init`, then `devenv allow` once per
  # project to let the hook auto-activate it on cd. The fish hook itself lives
  # in features/fish's shared fishConfig, so the standalone wrapped fish gets
  # it too; this module only installs the CLI.
  flake.nixosModules.devenv = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.devenv ];
  };
}
