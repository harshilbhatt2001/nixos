{lib, ...}: let
  # ---------------------------------------------------------------------------
  # The shared keymap: one compositor-neutral table for the binds that need
  # a store path or should survive a compositor swap. features/hyprland
  # renders it to Lua at /run/hypr/keymap.lua, read by binds.lua in the
  # out-of-store hypr checkout; another compositor would get its own
  # translator next to toHyprlandLua.
  #
  # Keys are spelled "Mod+Shift+H", "XF86AudioMute", "Mod+WheelScrollRight";
  # `toHyprKey` translates. `Mod` is Super.
  #
  # Actions (compositor-neutral vocabulary; each translator maps them):
  #   spawn <args>            run a command; args[0] is a program *name*,
  #                           resolved on the /run/hypr-runtime-env PATH
  #   launcher                the app launcher (otter-launcher)
  #   music                   toggle the floating YouTube Music scratchpad
  #                           (spawns ytmdesktop on first use; special:music)
  #   close-window  quit  toggle-floating  maximize  fullscreen
  #   focus-{left,right,up,down}   move-{left,right,up,down}
  #   focus-workspace <n>     move-to-workspace <n>
  #   focus-workspace-{next,prev}  move-to-workspace-{next,prev}
  #   screenshot-{area,screen,window}
  #
  # Per-bind attributes: action (required), args, desc, locked (works on the
  # lock screen).
  # Anything only one compositor can do stays in that compositor's own config.
  # ---------------------------------------------------------------------------
  bind = action: attrs:
    {
      inherit action;
      args = [];
      desc = "";
      locked = false;
    }
    // attrs;
  act = action: desc: bind action {inherit desc;};
  spawn = args: desc: bind "spawn" {inherit args desc;};
  media = args: desc:
    bind "spawn" {
      inherit args desc;
      locked = true;
    };

  workspaceBinds = lib.listToAttrs (lib.concatMap (n: let
    s = toString n;
  in [
    (lib.nameValuePair "Mod+${s}" (bind "focus-workspace" {
      args = [n];
      desc = "focus workspace ${s}";
    }))
    (lib.nameValuePair "Mod+Ctrl+${s}" (bind "move-to-workspace" {
      args = [n];
      desc = "move window to workspace ${s}";
    }))
  ]) (lib.range 1 9));

  binds =
    {
      # Windows
      "Mod+Q" = act "close-window" "close window";
      "Mod+F" = act "maximize" "maximize window";
      "Mod+Shift+F" = act "fullscreen" "fullscreen window";
      "Mod+V" = act "toggle-floating" "toggle floating";
      "Mod+Shift+E" = act "quit" "exit the session";

      # Apps
      "Mod+Return" = spawn ["kitty"] "terminal (kitty)";
      "Mod+W" = spawn ["zen"] "browser (zen)";
      "Mod+D" = act "launcher" "app launcher";
      "Mod+S" = act "music" "toggle YouTube Music scratchpad";

      # Focus
      "Mod+H" = act "focus-left" "focus left";
      "Mod+L" = act "focus-right" "focus right";
      "Mod+J" = act "focus-down" "focus down";
      "Mod+K" = act "focus-up" "focus up";
      "Mod+Left" = act "focus-left" "focus left";
      "Mod+Right" = act "focus-right" "focus right";
      "Mod+Down" = act "focus-down" "focus down";
      "Mod+Up" = act "focus-up" "focus up";

      # Move windows/columns
      "Mod+Ctrl+H" = act "move-left" "move window left";
      "Mod+Ctrl+L" = act "move-right" "move window right";
      "Mod+Ctrl+J" = act "move-down" "move window down";
      "Mod+Ctrl+K" = act "move-up" "move window up";
      "Mod+Ctrl+Left" = act "move-left" "move window left";
      "Mod+Ctrl+Right" = act "move-right" "move window right";
      "Mod+Ctrl+Down" = act "move-down" "move window down";
      "Mod+Ctrl+Up" = act "move-up" "move window up";

      # Workspaces
      "Mod+U" = act "focus-workspace-next" "next workspace";
      "Mod+I" = act "focus-workspace-prev" "previous workspace";
      "Mod+Ctrl+U" = act "move-to-workspace-next" "move window to next workspace";
      "Mod+Ctrl+I" = act "move-to-workspace-prev" "move window to previous workspace";

      # Rapoo thumb wheel: it reports as horizontal scroll. Mod is required —
      # an unmodified scroll bind would swallow horizontal scrolling in every
      # app. Swap next/prev here if the direction feels backwards.
      "Mod+WheelScrollRight" = act "focus-workspace-next" "thumb wheel: next workspace";
      "Mod+WheelScrollLeft" = act "focus-workspace-prev" "thumb wheel: previous workspace";

      # Screenshots (no Mod)
      "Print" = act "screenshot-area" "screenshot area";
      "Ctrl+Print" = act "screenshot-screen" "screenshot monitor";
      "Alt+Print" = act "screenshot-window" "screenshot window";

      # Media keys, usable on the lock screen
      "XF86AudioRaiseVolume" = media ["wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "5%+"] "volume up";
      "XF86AudioLowerVolume" = media ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"] "volume down";
      "XF86AudioMute" = media ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"] "mute";
      "XF86AudioMicMute" = media ["wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"] "mute microphone";
      "XF86AudioPlay" = media ["playerctl" "play-pause"] "play/pause";
      "XF86AudioPause" = media ["playerctl" "play-pause"] "play/pause";
      "XF86AudioNext" = media ["playerctl" "next"] "next track";
      "XF86AudioPrev" = media ["playerctl" "previous"] "previous track";
      "XF86AudioStop" = media ["playerctl" "stop"] "stop playback";
    }
    // workspaceBinds;

  # --- hyprland --------------------------------------------------------------

  hyprMods = {
    Mod = "SUPER";
    Super = "SUPER";
    Shift = "SHIFT";
    Ctrl = "CTRL";
    Alt = "ALT";
  };
  hyprKeys = {
    Return = "RETURN";
    Space = "space";
    Print = "PRINT";
    Escape = "ESCAPE";
    Tab = "TAB";
    BackSpace = "BACKSPACE";
    Delete = "DELETE";
    Home = "HOME";
    End = "END";
    Left = "LEFT";
    Right = "RIGHT";
    Up = "UP";
    Down = "DOWN";
    Minus = "minus";
    Equal = "equal";
    Slash = "slash";
    Backslash = "backslash";
    BracketLeft = "bracketleft";
    BracketRight = "bracketright";
    Comma = "comma";
    Period = "period";
    Semicolon = "semicolon";
    Apostrophe = "apostrophe";
    Grave = "grave";
    WheelScrollUp = "mouse_up";
    WheelScrollDown = "mouse_down";
    WheelScrollLeft = "mouse_left";
    WheelScrollRight = "mouse_right";
    MouseLeft = "mouse:272";
    MouseRight = "mouse:273";
    MouseMiddle = "mouse:274";
    MouseBack = "mouse:275";
    MouseForward = "mouse:276";
  };

  # "Mod+Shift+H" → "SUPER + SHIFT + h" (the combo format hl.bind takes).
  toHyprKey = key: let
    parts = lib.splitString "+" key;
    mods = map (m: hyprMods.${m} or (throw "keymap: unknown modifier `${m}` in ${key}")) (lib.init parts);
    k = lib.last parts;
    k' =
      hyprKeys.${
        k
      } or (
        if builtins.stringLength k == 1
        then lib.toLower k
        else k
      );
  in
    lib.concatStringsSep " + " (mods ++ [k']);

  # A Lua chunk returning a list of { key, action, args, desc, locked }, in a
  # stable order. The action → dispatcher mapping lives in binds.lua, next to
  # the hyprland-only binds, since that side is out-of-store anyway.
  toHyprlandLua = let
    entries = map (key: {
      key = toHyprKey key;
      inherit (binds.${key}) action args desc locked;
    }) (lib.sort builtins.lessThan (builtins.attrNames binds));
  in
    "-- generated from modules/features/keymap in the nixos repo; do not edit\nreturn " + lib.generators.toLua {} entries + "\n";

  # Markdown table of the shared binds, for humans:
  #   nix eval --raw .#lib.keymap.cheatsheet
  # (Hyprland-only binds live in binds.lua; SUPER+SHIFT+backslash shows all.)
  cheatsheet = let
    row = key: let
      b = binds.${key};
    in "| `${key}` | ${
      if b.desc != ""
      then b.desc
      else b.action
    } |";
  in
    lib.concatStringsSep "\n" (["| Key | Does |" "| --- | --- |"] ++ map row (lib.sort builtins.lessThan (builtins.attrNames binds))) + "\n";
in {
  # No NixOS module and no package: pure data plus translators, exposed as a
  # flake lib so features/hyprland can pull it in by name.
  flake.lib.keymap = {inherit binds cheatsheet toHyprlandLua toHyprKey;};
}
