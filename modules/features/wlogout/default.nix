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
  perSystem = {pkgs, ...}: {
    packages.wlogout = inputs.wrappers.lib.wrapPackage ({...}: {
      inherit pkgs;
      package = pkgs.wlogout;
      flags = {
        # import the whole folder so style.css's relative url(icons/*.png)
        # references resolve next to it in the store
        "--css" = "${./.}/style.css";
        "--layout" = "${./.}/layout";
        "--buttons-per-row" = "5";
      };
    });
  };
}
