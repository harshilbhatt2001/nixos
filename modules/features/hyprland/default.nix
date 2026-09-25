{
  moduleWithSystem,
  self,
  inputs,
  ...
}: {
  flake.nixosModules.hyprland = moduleWithSystem ({self'}: {
    pkgs,
    lib,
    ...
  }: let
    inherit (self.lib) user;
    runtimePkgs = self'.packages.hyprland.passthru.runtimePackages;
    # Shared keymap (features/keymap) as a Lua chunk. binds.lua in the hypr
    # checkout dofile()s /run/hypr/keymap.lua and maps each action to a
    # dispatcher, so shared binds need a rebuild while the hyprland-only binds
    # in binds.lua keep their live-reload workflow.
    keymapLua = pkgs.writeText "hypr-keymap.lua" self.lib.keymap.toHyprlandLua;
  in {
    imports = [self.nixosModules.quickshell]; # its config link, see there

    programs.hyprland = {
      enable = true;
      package = self'.packages.hyprland;
      # The portal from the same hyprwm flake as the compositor, so the two
      # speak the same protocol revision (the wiki's advice for flake users).
      portalPackage = inputs.hyprland.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    # Installs hyprlock and its PAM service; without /etc/pam.d/hyprlock the
    # unlock falls back to PAM's `other` (pam_deny). wlogout's lock button
    # runs it.
    programs.hyprlock.enable = true;

    services.displayManager.defaultSession = "hyprland";

    environment.systemPackages = with pkgs; [
      gsettings-desktop-schemas
      # Also on the runtime PATH (which serves the binds); installed here too
      # so it's on PATH in terminals.
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
    # `hyprctl reload` with no rebuild. When the checkout is missing (fresh
    # install, before cloning), it falls back to the pushed config pinned by
    # the hyprland input, so the session still starts configured.
    # No trailing slash on the rm target — config may be a symlink into
    # $HOME and rm -rf must remove the link, never the checkout behind it.
    system.activationScripts.hyprConfig = lib.stringAfter ["specialfs"] ''
      mkdir -p /run/hypr
      rm -rf /run/hypr/config
      if [ -e ${user.home}/.config/hypr/hyprland.lua ]; then
        ln -sfn ${user.home}/.config/hypr /run/hypr/config
      else
        echo "hyprland: ${user.home}/.config/hypr missing, using the store copy" >&2
        ln -sfn ${inputs.hyprland} /run/hypr/config
      fi
      ln -sfn ${keymapLua} /run/hypr/keymap.lua
    '';
  });
  perSystem = {
    self',
    inputs',
    pkgs,
    ...
  }: {
    packages = {
      hyprland = inputs'.hyprland.packages.default.override {
        flags."--config" = "/run/hypr/config/hyprland.lua";
        env."MODULES_ROOT" = "/run/hypr/config/modules";
        # Everything the out-of-store lua config launches by name, linked
        # into /run/hypr-runtime-env/bin. Spelled out rather than trimmed
        # from the hypr flake's defaultRuntimePkgs, so upstream additions
        # can't leak in and nothing comes from that flake's own nixpkgs.
        runtimePackages = {
          inherit (pkgs) playerctl; # media keys
          inherit (pkgs) nemo; # file browser bind
          zen = self'.packages.zen-browser; # Mod+W
          wpaperd = self'.packages.wpaperd;
          kitty = self'.packages.kitty;
          otter-launcher = self'.packages.otter-launcher;
          quickshell = self'.packages.quickshell;
          wlogout = self'.packages.wlogout;
          grimblast = self'.packages.grimblast;
          way-edges = self'.packages.way-edges; # autostarted from events.lua
          inherit (pkgs) hyprpolkitagent; # polkit auth prompts; autostarted from events.lua
          ytmdesktop = self'.packages.ytmdesktop; # Mod+S scratchpad (sharedActions.music)
        };
      };
    };
  };
}
