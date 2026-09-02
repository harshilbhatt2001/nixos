{self, ...}: {
  # The pre-hyprland desktop environment, kept as its own group so it stays
  # selectable at the login screen (hyprland is the default session).
  flake.nixosModules.niriDesktop = {
    imports = with self.nixosModules; [
      niri
    ];
  };
}
