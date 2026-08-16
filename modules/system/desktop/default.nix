{ self, ... }: {
  # Shared desktop base plus the two selectable desktop-environment groups:
  #  - hyprland     (features/hyprland): the reference's custom DE — waybar,
  #                 quickshell, otter-launcher, wlogout, way-edges, wpaperd…
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

    # The legacy GNOME module used to enable these implicitly; this is the
    # subset the desktop actually depends on (the exact enable-diff of
    # dropping GNOME, minus GNOME-only daemons like accounts-daemon).
    hardware.bluetooth.enable = true; # waybar/quickshell bluetooth widgets
    services.upower.enable = true; # quickshell BatteryManager (UPower dbus)
    services.udisks2.enable = true; # removable-drive automount
    services.gvfs.enable = true; # trash/MTP/network shares in file managers
    services.avahi.enable = true; # network printer discovery for CUPS
  };
}
