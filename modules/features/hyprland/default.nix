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
  }: let
    modules = with self.nixosModules; [
      audio
      systemTheme
    ];

    runtimePkgs = self'.packages.hyprland.passthru.runtimePackages;
    lib = pkgs.lib;
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
      # Also in the wrapper's defaultRuntimePkgs (which serves the binds);
      # installed here too so it's on PATH in terminals and other sessions.
      grimblast
    ];

    system.activationScripts.hyprRuntimeEnv = lib.stringAfter ["specialfs"] ''
      mkdir -p /run/hypr-runtime-env/bin
      # purge links from previous generations so removed packages disappear
      find /run/hypr-runtime-env/bin -maxdepth 1 -type l -delete
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: pkg: ''
          ln -sfn ${lib.getExe pkg} /run/hypr-runtime-env/bin/${name}
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
    pkgs,
    ...
  }: {
    packages = {
      hyprland = inputs'.hyprland.packages.default.override {
        flags."--config" = "/run/hypr/config/hyprland.lua";
        env."MODULES_ROOT" = "/run/hypr/config/modules";
        runtimePackages =
          builtins.removeAttrs
          inputs.hyprland.lib.defaultRuntimePkgs.${system}
          # reference-author programs nothing here launches or binds anymore,
          # and firefox — the browser here is zen
          ["syncthing" "gotify-desktop" "wayvnc" "firefox" "dunst" "woomer" "waybar" "way-edges" "wshowkeys"]
          // {
            # PATH-resolved from the out-of-store lua config (binds.lua):
            # media keys and the Mod+W browser bind
            playerctl = pkgs.playerctl;
            zen = inputs'.zen-browser.packages.default;
            wpaperd = self'.packages.wpaperd;
            kitty = self'.packages.kitty;
            otter-launcher = self'.packages.otter-launcher;
            quickshell = self'.packages.quickshell;
            wlogout = self'.packages.wlogout;
            grimblast = self'.packages.grimblast;
          };
      };
    };
  };
}
