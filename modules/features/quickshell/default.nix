{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.quickshell = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      quickshell
    ];
  });
  perSystem = {pkgs, ...}: {
    packages.quickshell = inputs.wrappers.wrappers.quickshell.wrap {
      inherit pkgs;
      # Out-of-store config for live editing, like hyprland: --path points at
      # the local checkout of the config repo (also quickshell's native
      # default location), so edits apply on quickshell restart with no
      # rebuild. Store-pinned variant: configDir = inputs.quickshell;
      configDir = "/home/habh/.config/quickshell";
      # The bar's calendar shells out to gcalcli; the now-playing toast reads
      # cava's raw output for its visualizer.
      runtimePkgs = [pkgs.gcalcli pkgs.cava];
    };
  };
}
