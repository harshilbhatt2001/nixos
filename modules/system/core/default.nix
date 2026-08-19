{ self, ... }: {
  flake.nixosModules.core = { pkgs, ... }: {
    imports = with self.nixosModules; [
      user
      nix-settings
      locale
      plymouth
      sudo
    ];

    services.openssh.enable = true;

    # Everyday CLI baseline, from the reference's core (minus vim — neovim
    # is its own feature — and with free p7zip instead of p7zip-rar).
    environment.systemPackages = with pkgs; [
      unzip
      p7zip
      usbutils
      lsof
      libnotify
      wget
    ];

    # This value determines the NixOS release from which the default settings
    # for stateful data were taken. Leave it at the release of the first
    # install of this system.
    system.stateVersion = "26.05";
  };
}
