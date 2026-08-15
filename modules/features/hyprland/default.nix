{
  moduleWithSystem,
  self,
  inputs,
  ...
}: {
  flake.nixosModules.hyprland = moduleWithSystem ({
    self',
    pkgs,
    ...
  }: {config, ...}: let
    modules = with self.nixosModules; [
      audio
      systemTheme
    ];

    runtimePkgs = self'.packages.hyprland.passthru.runtimePackages;
    lib = pkgs.lib;

    runtimeTarget = name: pkg:
      if config.security.wrappers ? ${name}
      then "/run/wrappers/bin/${name}"
      else lib.getExe pkg;
  in {
    imports = modules;
    programs.hyprland = {
      enable = true;
      package = self'.packages.hyprland;
    };

    services.displayManager.defaultSession = "hyprland";
    services.xserver.enable = true;
    security.polkit.enable = true;

    environment.systemPackages = with pkgs; [
      hyprlock
      gsettings-desktop-schemas
    ];

    system.activationScripts.hyprRuntimeEnv = lib.stringAfter ["specialfs"] ''
      mkdir -p /run/hypr-runtime-env/bin
      # purge links from previous generations so removed packages disappear
      find /run/hypr-runtime-env/bin -maxdepth 1 -type l -delete
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: pkg: ''
          ln -sfn ${runtimeTarget name pkg} /run/hypr-runtime-env/bin/${name}
        '')
        runtimePkgs)}
    '';

    # Out-of-store config for live editing: /run/hypr/config points at the
    # local checkout of the hypr config repo, so edits there take effect on
    # `hyprctl reload` with no rebuild. The reference links the store copy
    # instead (ln -sfn ''${inputs'.hyprland.packages.repo-files}/* ...).
    # No trailing slash on the rm target — config may be a symlink into
    # $HOME and rm -rf must remove the link, never the checkout behind it.
    system.activationScripts.hyprConfig = lib.stringAfter ["specialfs"] ''
      mkdir -p /run/hypr
      rm -rf /run/hypr/config
      ln -sfn /home/habh/.config/hypr /run/hypr/config
    '';
  });
  perSystem = {
    self',
    system,
    inputs',
    ...
  }: {
    packages = {
      hyprland = inputs'.hyprland.packages.default.override {
        flags."--config" = "/run/hypr/config/hyprland.lua";
        env."MODULES_ROOT" = "/run/hypr/config/modules";
        runtimePackages =
          builtins.removeAttrs
          inputs.hyprland.lib.defaultRuntimePkgs.${system}
          # reference-author services nothing here launches anymore
          ["syncthing" "gotify-desktop" "wayvnc"]
          // {
            wpaperd = self'.packages.wpaperd;
            kitty = self'.packages.kitty;
            otter-launcher = self'.packages.otter-launcher;
            quickshell = self'.packages.quickshell;
            wshowkeys = self'.packages.wshowkeys;
            waybar = self'.packages.waybar;
            wlogout = self'.packages.wlogout;
            way-edges = self'.packages.way-edges;
          };
      };
    };
  };
}
