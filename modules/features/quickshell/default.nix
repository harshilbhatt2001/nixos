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
      configDir = inputs.quickshell;
      configFile = "${inputs.quickshell}/shell.qml";
    };
  };
}
