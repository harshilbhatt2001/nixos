{moduleWithSystem, ...}: {
  # Nothing to wrap — ytmdesktop keeps its own config — but both compositors
  # reference it by name for the Mod+S music scratchpad (features/keymap
  # action `music`): niri resolves self'.packages.ytmdesktop to a store path,
  # hyprland puts it on the /run/hypr-runtime-env PATH for binds.lua.
  # Electron: without NIXOS_OZONE_WL it runs under XWayland; the window rules
  # match both the X11 and the Wayland spelling of its class.
  flake.nixosModules.ytmdesktop = moduleWithSystem ({self', ...}: {
    environment.systemPackages = [self'.packages.ytmdesktop];
  });
  perSystem = {pkgs, ...}: {
    packages.ytmdesktop = pkgs.ytmdesktop;
  };
}
