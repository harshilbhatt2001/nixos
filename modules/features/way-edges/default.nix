{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.way-edges = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      way-edges
    ];
  });
  perSystem = {pkgs, ...}: {
    packages.way-edges = inputs.wrappers.lib.wrapPackage ({...}: {
      inherit pkgs;
      package = pkgs.way-edges;
      flags = {
        "--config-path" = ./config.jsonc;
      };
    });
  };
}
