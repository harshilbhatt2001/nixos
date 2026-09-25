{...}: {
  flake.nixosModules.bibataCursors = {pkgs, ...}: {
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
