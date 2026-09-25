{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.otter-launcher = self.lib.installFeature "otter-launcher";
  perSystem = {
    pkgs,
    lib,
    inputs',
    self',
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
        # become absolute store paths. PATH additions don't survive into module
        # commands — fish -c re-sources /etc/set-environment (resetting PATH)
        # when the session lacks __NIXOS_SET_ENVIRONMENT_DONE. hyprctl is left
        # PATH-resolved — going through self'.packages.hyprland would be a
        # dependency cycle, since this package sits in hyprland's
        # runtimePackages.
        final-config = pkgs.writeText "config.toml" ''
          ${extra-config}

          ${builtins.replaceStrings
            ["@fish@" "@browser@" "@fsel@" "@bluetui@" "@wiremix@" "@wallpaper-picker@"]
            [
              (lib.getExe pkgs.fish)
              (lib.getExe self'.packages.zen-browser)
              (lib.getExe pkgs.fsel)
              (lib.getExe pkgs.bluetui)
              (lib.getExe pkgs.wiremix)
              (lib.getExe self'.packages.wallpaper-picker)
            ]
            (builtins.readFile ./config.toml)}
        '';
      in
        inputs.wrappers.lib.wrapPackage ({...}: {
          inherit pkgs;
          package = inputs'.otter-launcher.packages.default;
          flags = {
            "-c" = final-config;
          };
        });
    };
  };
}
