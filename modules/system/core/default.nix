{ self, ... }: {
  flake.nixosModules.core = {
    imports = with self.nixosModules; [
      user
      nix-settings
      locale
    ];

    # This value determines the NixOS release from which the default settings
    # for stateful data were taken. Leave it at the release of the first
    # install of this system.
    system.stateVersion = "26.05";
  };
}
