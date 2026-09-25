{moduleWithSystem, ...}: {
  # Nothing to wrap — ytmdesktop keeps its own config — but hyprland puts it
  # on the /run/hypr-runtime-env PATH for binds.lua's Mod+S music scratchpad
  # (features/keymap action `music`).
  # Electron: without NIXOS_OZONE_WL it runs under XWayland; the window rules
  # match both the X11 and the Wayland spelling of its class.
  flake.nixosModules.ytmdesktop = moduleWithSystem ({self', ...}: {
    environment.systemPackages = [self'.packages.ytmdesktop];
  });
  perSystem = {pkgs, ...}: {
    packages.ytmdesktop = pkgs.ytmdesktop;
  };
}
