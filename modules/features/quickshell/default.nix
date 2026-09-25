{
  self,
  moduleWithSystem,
  inputs,
  ...
}: let
  # Stable path the wrapper points at; the NixOS module below links it.
  configLink = "/run/quickshell/config";
in {
  flake.nixosModules.quickshell = moduleWithSystem ({self'}: {lib, ...}: let
    inherit (self.lib) user;
  in {
    environment.systemPackages = [self'.packages.quickshell];

    # Out-of-store config for live editing, like hyprland: the link points at
    # the local checkout of the config repo, so edits apply on quickshell
    # restart with no rebuild. Falls back to the pushed config pinned by the
    # quickshell input when the checkout is missing.
    system.activationScripts.quickshellConfig = lib.stringAfter ["specialfs"] ''
      mkdir -p ${dirOf configLink}
      rm -f ${configLink}
      if [ -e ${user.home}/.config/quickshell/shell.qml ]; then
        ln -sfn ${user.home}/.config/quickshell ${configLink}
      else
        echo "quickshell: ${user.home}/.config/quickshell missing, using the store copy" >&2
        ln -sfn ${inputs.quickshell} ${configLink}
      fi
    '';
  });
  perSystem = {pkgs, ...}: {
    packages.quickshell = inputs.wrappers.wrappers.quickshell.wrap {
      inherit pkgs;
      # Linked by the NixOS module above (checkout or store fallback).
      configDir = configLink;
      # The bar's calendar shells out to gcalcli; the now-playing toast reads
      # cava's raw output for its visualizer.
      runtimePkgs = [pkgs.gcalcli pkgs.cava];
    };
  };
}
