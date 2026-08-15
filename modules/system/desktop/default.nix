{ self, ... }: {
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      core
      network
      audio
      niri
      zen-browser
    ];

    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Legacy installer desktop, still enabled alongside niri. Migration in
    # progress — remove deliberately, not as a side effect of other work.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;
  };
}
