{ ... }: {
  flake.nixosModules.git = {
    programs.git.enable = true;
  };
}
