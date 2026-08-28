{...}: {
  flake.nixosModules.bibataCursors = {pkgs, ...}: {
    fonts.packages = with pkgs.nerd-fonts; [
      fira-mono
      jetbrains-mono # hyprlock.conf's $font
    ];
    environment.systemPackages = with pkgs; [
      bibata-cursors
    ];

    environment.variables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "20";
    };

    programs.dconf.profiles.user.databases = [
      {
        lockAll = false;
        settings = {
          "org/gnome/desktop/interface" = {
            cursor-theme = "Bibata-Modern-Ice";
            font-name = "FiraMono Nerd Font 11";
          };
        };
      }
    ];
  };
}
