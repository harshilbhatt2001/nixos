{self, ...}: {
  # Shared desktop base plus the two selectable desktop-environment groups:
  #  - hyprland     (features/hyprland): the reference's custom DE —
  #                 quickshell, otter-launcher, wlogout, wpaperd…
  #                 It sets services.displayManager.defaultSession, so it is
  #                 the default session at the login screen.
  #  - niriDesktop  (./niri.nix): the pre-hyprland setup, now just niri
  #                 (the legacy installer GNOME + GDM are gone; sddm is the
  #                 display manager for every session).
  # Drop either group here to remove that environment wholesale.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      core
      network
      audio
      zen-browser
      kitty
      sddm
      hyprland
      niriDesktop
    ];

    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    hardware.bluetooth.enable = true; # waybar/quickshell bluetooth widgets
    services.upower.enable = true; # quickshell BatteryManager (UPower dbus)
    services.udisks2.enable = true; # removable-drive automount
    services.gvfs.enable = true; # trash/MTP/network shares in file managers
    services.avahi.enable = true; # network printer discovery for CUPS

    # Secret Service for portals/apps; sddm's PAM hook (features/sddm) unlocks
    # it at login. Pinned here explicitly — it otherwise rides in only via
    # programs.niri's module, and dropping niriDesktop would silently lose it.
    services.gnome.gnome-keyring.enable = true;
  };
}
