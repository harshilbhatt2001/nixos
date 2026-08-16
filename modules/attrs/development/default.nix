{ self, ... }: {
  # Composition: imports of other modules + plain packages, no new features
  # defined here.
  flake.nixosModules.development = { pkgs, ... }: {
    imports = with self.nixosModules; [
      devenv
      git
      lazygit
      neovim
    ];

    environment.systemPackages = with pkgs; [
      claude-code
      opencode
    ];
  };
}
