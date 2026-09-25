{...}: {
  flake.nixosModules.sddm = {pkgs, ...}: {
    environment.systemPackages = [
      (pkgs.catppuccin-sddm.override {
        flavor = "mocha";
        font = "FiraMono Nerd Font";
        fontSize = "11";
        background = null;
      })
    ];
    services.displayManager.sddm = {
      enable = true;
      theme = "catppuccin-mocha-mauve";
      package = pkgs.kdePackages.sddm;
    };
    # GDM auto-unlocked gnome-keyring at login; SDDM needs this opt-in or
    # every keyring consumer prompts for the password after login. (The
    # keyring service itself is enabled in system/desktop.)
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
