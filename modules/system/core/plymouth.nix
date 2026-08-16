{ ... }: {
  # Graphical boot splash, themed like the rest of the system. Bootloader-
  # agnostic (runs from the initrd), so it composes with anton's Limine
  # chain; amdDrivers' early KMS is what makes it render immediately.
  flake.nixosModules.plymouth = { pkgs, ... }: {
    boot.plymouth = {
      enable = true;
      theme = "catppuccin-mocha";
      themePackages = [
        # By default the package would install all flavors
        (pkgs.catppuccin-plymouth.override { variant = "mocha"; })
      ];
    };
    boot.loader.timeout = 2;
  };
}
