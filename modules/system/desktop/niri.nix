{ self, ... }: {
  # The pre-hyprland desktop environment, kept as its own group so it stays
  # selectable at the login screen (hyprland is the default session).
  flake.nixosModules.niriDesktop = {
    imports = with self.nixosModules; [
      niri
    ];

    # Legacy installer desktop, still enabled alongside niri. Migration in
    # progress — remove deliberately, not as a side effect of other work.
    # (GDM is gone: features/sddm is the display manager for every session
    # now, GNOME included — NixOS allows only one display manager.)
    services.desktopManager.gnome.enable = true;
  };
}
