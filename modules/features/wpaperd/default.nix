{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.wpaperd = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      wpaperd
    ];
  });
  perSystem = {pkgs, ...}: {
    packages.wpaperd = let
      config-file = builtins.toFile "config.toml" ''
        [any]
        path = "${./wallpapers}"

        [HDMI-A-1]
        path = "${./wallpapers/topo1.png}"

        [DP-1]
        path = "${./wallpapers/topo2.png}"

        [DP-2]
        path = "${./wallpapers/topo3.png}"
      '';
    in
      inputs.wrappers.lib.wrapPackage ({...}: {
        inherit pkgs;
        package = pkgs.wpaperd;
        flags = {
          "--config" = config-file;
        };
      });
  };
}
