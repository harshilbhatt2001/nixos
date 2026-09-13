{
  self,
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.niri = moduleWithSystem (
    {self'}: {
      programs.niri = {
        enable = true;
        package = self'.packages.niri;
      };
    }
  );

  perSystem = {
    pkgs,
    lib,
    self',
    inputs',
    ...
  }: {
    packages.niri = let
      # Regex for ytmdesktop's window class: Electron reports the X11 spelling
      # under XWayland and the kebab-case one on native Wayland.
      ytmClass = "^(YouTube Music Desktop App|youtube-music-desktop-app)$";
      # Shared keymap action `music` (Mod+S): niri has no special workspaces,
      # so the scratchpad is a named workspace "music" that the bind toggles
      # to and from; the window rule below floats ytmdesktop onto it. First
      # press spawns it. `niri msg` comes from PATH on purpose — this *is* the
      # niri package being defined, so it cannot reference itself.
      musicToggle = pkgs.writeShellScript "niri-music-toggle" ''
        if ! ${pkgs.procps}/bin/pgrep -f ytmdesktop >/dev/null; then
          ${pkgs.util-linux}/bin/setsid -f ${lib.getExe self'.packages.ytmdesktop} >/dev/null 2>&1
        fi
        if niri msg -j workspaces | ${lib.getExe pkgs.jq} -e 'any(.[]; .is_focused and .name == "music")' >/dev/null; then
          niri msg action focus-workspace-previous
        else
          niri msg action focus-workspace music
        fi
      '';
    in
      inputs.wrappers.wrappers.niri.wrap {
        inherit pkgs; # required: `wrap` takes no implicit pkgs
        settings = {
          spawn-at-startup = [
            (lib.getExe self'.packages.noctalia)
            (lib.getExe self'.packages.way-edges)
          ];

          workspaces.music = _: {}; # ytmdesktop scratchpad, see musicToggle
          window-rules = [
            {
              matches = [{app-id = ytmClass;}];
              open-floating = true;
              open-on-workspace = "music";
            }
          ];

          xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

          input.keyboard.xkb.layout = "us";

          layout = {
            gaps = 5;
            preset-column-widths = [
              {proportion = 1.0 / 3.0;}
              {proportion = 1.0 / 2.0;}
              {proportion = 2.0 / 3.0;}
            ];
          };

          # Shared keymap (features/keymap) rendered to niri, then niri-only
          # binds. Anything both compositors can do belongs in the shared table.
          binds =
            self.lib.keymap.toNiri {
              resolve = {
                kitty = lib.getExe self'.packages.kitty;
                zen = lib.getExe inputs'.zen-browser.packages.default;
                wpctl = "${pkgs.wireplumber}/bin/wpctl";
                playerctl = lib.getExe pkgs.playerctl;
              };
              actions = {
                launcher = _: {spawn-sh = "${lib.getExe self'.packages.noctalia} ipc call launcher toggle";};
                music = _: {spawn-sh = "${musicToggle}";};
              };
            }
            // {
              # `_: {}` renders an action with no arguments; `null` would emit a
              # literal KDL `null` argument and fail the build-time config check.
              "Mod+Shift+Slash".show-hotkey-overlay = _: {};
              "Mod+O".toggle-overview = _: {};
              "Mod+Space".switch-layout = "next";

              "Mod+Home".focus-column-first = _: {};
              "Mod+End".focus-column-last = _: {};
              "Mod+Shift+U".move-workspace-down = _: {};
              "Mod+Shift+I".move-workspace-up = _: {};

              # Column/window sizing
              "Mod+R".switch-preset-column-width = _: {};
              "Mod+Shift+R".switch-preset-window-height = _: {};
              "Mod+Ctrl+R".reset-window-height = _: {};
              "Mod+Minus".set-column-width = "-10%";
              "Mod+Equal".set-column-width = "+10%";
              "Mod+Shift+Minus".set-window-height = "-10%";
              "Mod+Shift+Equal".set-window-height = "+10%";
              "Mod+Ctrl+F".expand-column-to-available-width = _: {};
              "Mod+C".center-column = _: {};

              # Column composition / floating / tabs
              "Mod+BracketLeft".consume-or-expel-window-left = _: {};
              "Mod+BracketRight".consume-or-expel-window-right = _: {};
              "Mod+Shift+V".switch-focus-between-floating-and-tiling = _: {};
              "Mod+T".toggle-column-tabbed-display = _: {};

              # Brightness keys: laptop-only, so not in the shared table
              "XF86MonBrightnessUp" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "${lib.getExe pkgs.brightnessctl} set 5%+";
              };
              "XF86MonBrightnessDown" = _: {
                props.allow-when-locked = true;
                content.spawn-sh = "${lib.getExe pkgs.brightnessctl} set 5%-";
              };
            };
        };
      };
  };
}
