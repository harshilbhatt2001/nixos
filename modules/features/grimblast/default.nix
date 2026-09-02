{...}: {
  # Nothing to wrap — grimblast takes no config — but the hyprland runtime
  # env references it as self'.packages.grimblast (binds.lua screenshot
  # keys), and every feature is independently runnable: nix run .#grimblast.
  perSystem = {pkgs, ...}: {
    packages.grimblast = pkgs.grimblast;
  };
}
