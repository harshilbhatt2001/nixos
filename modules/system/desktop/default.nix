{ self, ... }: {
  # Shared desktop base plus the two selectable desktop-environment groups:
  #  - hyprland     (features/hyprland): the reference's custom DE — waybar,
  #                 quickshell, otter-launcher, wlogout, way-edges, wpaperd…
  #                 It sets services.displayManager.defaultSession, so it is
  #                 the default session at the login screen.
  #  - niriDesktop  (./niri.nix): the pre-hyprland setup — niri plus the
  #                 legacy installer GNOME + GDM.
  # Drop either group here to remove that environment wholesale.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      core
      network
      audio
      zen-browser
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
  };
}
