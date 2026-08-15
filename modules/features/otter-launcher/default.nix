{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.otter-launcher = moduleWithSystem ({self', ...}: {
    environment.systemPackages = [
      self'.packages.otter-launcher
    ];
  });
  perSystem = {
    pkgs,
    lib,
    inputs',
    ...
  }: {
    packages = {
      otter-launcher = let
        extra-config = ''
          [overlay]
          overlay_cmd = "${lib.getExe pkgs.kitty} +kitten icat --fit height --align left --no-trailing-newline ${./cat.png}"
          overlay_trimmed_lines = 0
        '';
        final-config = pkgs.writeText "config.toml" ''
          ${extra-config}

          ${builtins.readFile ./config.toml}
        '';
      in
        inputs.wrappers.lib.wrapPackage ({...}: {
          inherit pkgs;
          package = inputs'.otter-launcher.packages.default;
          runtimePkgs = with pkgs; [
            fsel
            bluetui
          ];
          flags = {
            "-c" = final-config;
          };
        });
    };
  };
}
