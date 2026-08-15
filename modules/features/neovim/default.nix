{ moduleWithSystem, ... }: {
  flake.nixosModules.neovim = moduleWithSystem (
    { self' }: {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        package = self'.packages.neovim;
      };
    }
  );

  perSystem = { inputs', ... }: {
    packages.neovim = inputs'.nvim.packages.default;
  };
}
