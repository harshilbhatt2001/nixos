{ self, ... }: {
  # Composition only — imports of other modules, no new features defined here.
  flake.nixosModules.development = {
    imports = with self.nixosModules; [
      git
      neovim
    ];
  };
}
