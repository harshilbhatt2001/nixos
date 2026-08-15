{self, ...}: {
  flake.nixosModules.systemTheme = {...}: let
    modules = with self.nixosModules; [
      bibataCursors
      catppuccinGtk
    ];
  in {
    imports = modules;
  };
}
