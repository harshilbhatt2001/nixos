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
        # close the config over the store: @name@ placeholders in config.toml
        # become absolute store paths. hyprctl is left PATH-resolved — going
        # through self'.packages.hyprland would be a dependency cycle, since
        # this package sits in hyprland's runtimePackages.
        final-config = pkgs.writeText "config.toml" ''
          ${extra-config}

          ${builtins.replaceStrings
            ["@fish@" "@browser@"]
            [(lib.getExe pkgs.fish) (lib.getExe inputs'.zen-browser.packages.default)]
            (builtins.readFile ./config.toml)}
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
