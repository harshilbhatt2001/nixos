{self, ...}: {
  flake.nixosModules.core = {pkgs, ...}: {
    imports = with self.nixosModules; [
      user
      nix-settings
      locale
      plymouth
      sudo
    ];

    # Keys only: ~/.ssh/authorized_keys, no passwords or root logins.
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Everyday CLI baseline, from the reference's core (minus vim — neovim
    # is its own feature — and with free p7zip instead of p7zip-rar).
    environment.systemPackages = with pkgs; [
      unzip
      p7zip
      usbutils
      lsof
      libnotify
      wget
      jq
    ];
  };
}
