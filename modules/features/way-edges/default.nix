{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.way-edges = self.lib.installFeature "way-edges";
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
