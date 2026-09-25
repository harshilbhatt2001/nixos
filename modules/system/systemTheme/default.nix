{self, ...}: {
  flake.nixosModules.systemTheme = {...}: let
    modules = with self.nixosModules; [
      bibataCursors
      catppuccinGtk
      fonts
    ];
  in {
    imports = modules;
  };
}
