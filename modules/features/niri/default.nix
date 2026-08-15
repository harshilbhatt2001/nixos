{ inputs, moduleWithSystem, ... }: {
  flake.nixosModules.niri = moduleWithSystem (
    { self' }: {
      programs.niri = {
        enable = true;
        package = self'.packages.niri;
      };
    }
  );

  perSystem = { pkgs, lib, self', inputs', ... }: {
    packages.niri = inputs.wrappers.wrappers.niri.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!
      settings = {
        spawn-at-startup = [
          (lib.getExe self'.packages.noctalia)
        ];

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        input.keyboard.xkb.layout = "us,ua";

        layout = {
          gaps = 5;
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];
        };

        binds = {
          "Mod+Return".spawn-sh = lib.getExe pkgs.kitty;
          # `_: { }` renders an action with no arguments; `null` would emit a
          # literal KDL `null` argument and fail the build-time config check.
          "Mod+Q".close-window = _: { };
          "Mod+D".spawn-sh = "${lib.getExe self'.packages.noctalia} ipc call launcher toggle";
          "Mod+W".spawn-sh = lib.getExe inputs'.zen-browser.packages.default;

          "Mod+Shift+Slash".show-hotkey-overlay = _: { };
          "Mod+O".toggle-overview = _: { };
          "Mod+Shift+E".quit = _: { };
          "Mod+Space".switch-layout = "next";

          # Focus
          "Mod+H".focus-column-left = _: { };
          "Mod+L".focus-column-right = _: { };
          "Mod+J".focus-window-or-workspace-down = _: { };
          "Mod+K".focus-window-or-workspace-up = _: { };
          "Mod+Left".focus-column-left = _: { };
          "Mod+Right".focus-column-right = _: { };
          "Mod+Down".focus-window-or-workspace-down = _: { };
          "Mod+Up".focus-window-or-workspace-up = _: { };
          "Mod+Home".focus-column-first = _: { };
          "Mod+End".focus-column-last = _: { };

          # Move windows/columns
          "Mod+Ctrl+H".move-column-left = _: { };
          "Mod+Ctrl+L".move-column-right = _: { };
          "Mod+Ctrl+J".move-window-down-or-to-workspace-down = _: { };
          "Mod+Ctrl+K".move-window-up-or-to-workspace-up = _: { };
          "Mod+Ctrl+Left".move-column-left = _: { };
          "Mod+Ctrl+Right".move-column-right = _: { };
          "Mod+Ctrl+Down".move-window-down-or-to-workspace-down = _: { };
          "Mod+Ctrl+Up".move-window-up-or-to-workspace-up = _: { };

          # Workspaces
          "Mod+U".focus-workspace-down = _: { };
          "Mod+I".focus-workspace-up = _: { };
          "Mod+Ctrl+U".move-column-to-workspace-down = _: { };
          "Mod+Ctrl+I".move-column-to-workspace-up = _: { };
          "Mod+Shift+U".move-workspace-down = _: { };
          "Mod+Shift+I".move-workspace-up = _: { };
          "Mod+1".focus-workspace = 1;
          "Mod+2".focus-workspace = 2;
          "Mod+3".focus-workspace = 3;
          "Mod+4".focus-workspace = 4;
          "Mod+5".focus-workspace = 5;
          "Mod+6".focus-workspace = 6;
          "Mod+7".focus-workspace = 7;
          "Mod+8".focus-workspace = 8;
          "Mod+9".focus-workspace = 9;
          "Mod+Ctrl+1".move-column-to-workspace = 1;
          "Mod+Ctrl+2".move-column-to-workspace = 2;
          "Mod+Ctrl+3".move-column-to-workspace = 3;
          "Mod+Ctrl+4".move-column-to-workspace = 4;
          "Mod+Ctrl+5".move-column-to-workspace = 5;
          "Mod+Ctrl+6".move-column-to-workspace = 6;
          "Mod+Ctrl+7".move-column-to-workspace = 7;
          "Mod+Ctrl+8".move-column-to-workspace = 8;
          "Mod+Ctrl+9".move-column-to-workspace = 9;

          # Column/window sizing
          "Mod+R".switch-preset-column-width = _: { };
          "Mod+Shift+R".switch-preset-window-height = _: { };
          "Mod+Ctrl+R".reset-window-height = _: { };
          "Mod+Minus".set-column-width = "-10%";
          "Mod+Equal".set-column-width = "+10%";
          "Mod+Shift+Minus".set-window-height = "-10%";
          "Mod+Shift+Equal".set-window-height = "+10%";
          "Mod+F".maximize-column = _: { };
          "Mod+Shift+F".fullscreen-window = _: { };
          "Mod+Ctrl+F".expand-column-to-available-width = _: { };
          "Mod+C".center-column = _: { };

          # Column composition / floating / tabs
          "Mod+BracketLeft".consume-or-expel-window-left = _: { };
          "Mod+BracketRight".consume-or-expel-window-right = _: { };
          "Mod+V".toggle-window-floating = _: { };
          "Mod+Shift+V".switch-focus-between-floating-and-tiling = _: { };
          "Mod+T".toggle-column-tabbed-display = _: { };

          # Screenshots (niri built-ins, no external tool needed)
          "Print".screenshot = _: { };
          "Ctrl+Print".screenshot-screen = _: { };
          "Alt+Print".screenshot-window = _: { };

          # Media keys — work on the lock screen too
          "XF86AudioRaiseVolume" = _: {
            props.allow-when-locked = true;
            content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          };
          "XF86AudioLowerVolume" = _: {
            props.allow-when-locked = true;
            content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          };
          "XF86AudioMute" = _: {
            props.allow-when-locked = true;
            content.spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };
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
