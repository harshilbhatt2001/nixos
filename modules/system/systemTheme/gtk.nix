{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.catppuccinGtk = {
    pkgs,
    lib,
    ...
  }: let
  in {
    environment.systemPackages = with pkgs; [
      (catppuccin-gtk.override {
        variant = "mocha";
        accents = ["mauve"];
        tweaks = ["rimless"];
        size = "compact";
      })
      (catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "mauve";
      })
    ];
    programs = {
      xfconf.enable = true;
      dconf = {
        enable = true;
        profiles.user.databases = [
          {
            lockAll = false;
            settings = {
              "org/gnome/desktop/interface" = {
                gtk-theme = "catppuccin-mocha-mauve-compact+rimless";
                icon-theme = "Papirus";
                color-scheme = "prefer-dark";
              };
            };
          }
        ];
      };
    };
  };
}
