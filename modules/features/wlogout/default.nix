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
        "--css" = ./style.css;
        "--layout" = ./layout;
        "--buttons-per-row" = "5";
      };
    });
  };
}
