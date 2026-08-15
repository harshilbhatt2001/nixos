{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.quickshell = moduleWithSystem ({
    self',
    pkgs,
    ...
  }: {
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
    };
  };
}
