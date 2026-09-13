{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations.anton = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      desktop
      development
      fish
      nix-ld
      amdDrivers
      intelDrivers
      ddcci
      antonHardware
      antonConfiguration
    ];
  };
}
