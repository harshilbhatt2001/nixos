{ self, ... }: {
  # Composition: imports of other modules + plain packages, no new features
  # defined here.
  flake.nixosModules.development = { pkgs, ... }: {
    imports = with self.nixosModules; [
      git
      neovim
    ];

    environment.systemPackages = with pkgs; [
      claude-code
      devenv # per-project dev environments: `devenv init` (see README)
    ];
  };
}
