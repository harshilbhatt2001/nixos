{ ... }: {
  flake.nixosModules.neovim = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
