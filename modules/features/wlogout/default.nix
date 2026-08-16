{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.wlogout = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      wlogout
    ];
  });
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    packages.wlogout = inputs.wrappers.lib.wrapPackage ({...}: {
      inherit pkgs;
      package = pkgs.wlogout;
      flags = {
        # import the whole folder so style.css's relative url(icons/*.png)
        # references resolve next to it in the store
        "--css" = "${./.}/style.css";
        # close the layout over the store. hyprctl stays PATH-resolved:
        # referencing self'.packages.hyprland here would be a dependency
        # cycle, since wlogout sits in hyprland's runtimePackages.
        "--layout" = pkgs.writeText "wlogout-layout" (builtins.replaceStrings
          ["@hyprlock@" "@systemctl@"]
          [(lib.getExe pkgs.hyprlock) "${pkgs.systemd}/bin/systemctl"]
          (builtins.readFile ./layout));
        "--buttons-per-row" = "5";
        # shrink the fullscreen layer to a centered cluster of ~330x350 cards;
        # values are logical px on the native 2560x1440 screen
        "--margin-top" = "545";
        "--margin-bottom" = "545";
        "--margin-left" = "455";
        "--margin-right" = "455";
      };
    });
  };
}
