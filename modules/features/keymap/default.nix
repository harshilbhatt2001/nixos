{lib, ...}: let
  # ---------------------------------------------------------------------------
  # The shared keymap: one compositor-neutral table, consumed by every desktop
  # environment in this repo.
  #
  #   - niri      features/niri renders it into the wrapper's KDL `binds`
  #   - hyprland  features/hyprland renders it to Lua at /run/hypr/keymap.lua,
  #               read by binds.lua in the out-of-store hypr checkout
  #
  # Keys use niri's spelling ("Mod+Shift+H", "XF86AudioMute",
  # "Mod+WheelScrollRight"); `toHyprland` translates. `Mod` is Super.
  #
  # Actions (compositor-neutral vocabulary; each translator maps them):
  #   spawn <args>            run a command; args[0] is a program *name*, resolved
  #                           per compositor (niri: store path, hyprland: the
  #                           /run/hypr-runtime-env PATH)
  #   launcher                the app launcher (noctalia on niri, otter on hypr)
  #   music                   toggle the floating YouTube Music scratchpad
  #                           (spawns ytmdesktop on first use; hyprland:
  #                           special:music, niri: named workspace "music")
  #   close-window  quit  toggle-floating  maximize  fullscreen
  #   focus-{left,right,up,down}   move-{left,right,up,down}
  #   focus-workspace <n>     move-to-workspace <n>
  #   focus-workspace-{next,prev}  move-to-workspace-{next,prev}
  #   screenshot-{area,screen,window}
  #
  # Per-bind attributes: action (required), args, desc, locked (works on the
  # lock screen), cooldown (ms; only scroll binds need it, niri honours it).
  # Anything only one compositor can do stays in that compositor's own config.
  # ---------------------------------------------------------------------------
  bind = action: attrs:
    {
      inherit action;
      args = [];
      desc = "";
      locked = false;
      cooldown = null;
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
      "Mod+WheelScrollRight" = bind "focus-workspace-next" {
        desc = "thumb wheel: next workspace";
        cooldown = 150;
      };
      "Mod+WheelScrollLeft" = bind "focus-workspace-prev" {
        desc = "thumb wheel: previous workspace";
        cooldown = 150;
      };

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

  # --- niri ------------------------------------------------------------------

  # Default action → KDL node. Overridable per action by the caller.
  niriActions = {
    close-window = _: {close-window = _: {};};
    quit = _: {quit = _: {};};
    toggle-floating = _: {toggle-window-floating = _: {};};
    maximize = _: {maximize-column = _: {};};
    fullscreen = _: {fullscreen-window = _: {};};
    focus-left = _: {focus-column-left = _: {};};
    focus-right = _: {focus-column-right = _: {};};
    focus-up = _: {focus-window-or-workspace-up = _: {};};
    focus-down = _: {focus-window-or-workspace-down = _: {};};
    move-left = _: {move-column-left = _: {};};
    move-right = _: {move-column-right = _: {};};
    move-up = _: {move-window-up-or-to-workspace-up = _: {};};
    move-down = _: {move-window-down-or-to-workspace-down = _: {};};
    focus-workspace = b: {focus-workspace = builtins.head b.args;};
    move-to-workspace = b: {move-column-to-workspace = builtins.head b.args;};
    focus-workspace-next = _: {focus-workspace-down = _: {};};
    focus-workspace-prev = _: {focus-workspace-up = _: {};};
    move-to-workspace-next = _: {move-column-to-workspace-down = _: {};};
    move-to-workspace-prev = _: {move-column-to-workspace-up = _: {};};
    screenshot-area = _: {screenshot = _: {};};
    screenshot-screen = _: {screenshot-screen = _: {};};
    screenshot-window = _: {screenshot-window = _: {};};
  };

  # toNiri { resolve = { kitty = "/nix/store/…/bin/kitty"; … }; actions = { launcher = …; }; }
  #   resolve: program name → executable, for spawn's args[0]; unresolved names
  #            fall through as-is (PATH lookup at runtime).
  #   actions: extra/overriding action translators (bind → KDL node attrset).
  toNiri = {
    resolve ? {},
    actions ? {},
  }: let
    translators =
      niriActions
      // {
        spawn = b: {
          spawn-sh = lib.escapeShellArgs ([(resolve.${builtins.head b.args} or (builtins.head b.args))] ++ builtins.tail b.args);
        };
      }
      // actions;
    render = key: b: let
      content = (translators.${b.action} or (throw "keymap: no niri translation for action `${b.action}` (bind ${key})")) b;
      props =
        lib.optionalAttrs b.locked {allow-when-locked = true;}
        // lib.optionalAttrs (b.cooldown != null) {cooldown-ms = b.cooldown;};
    in
      if props == {}
      then content
      else _: {inherit props content;};
  in
    lib.mapAttrs render binds;

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
in {
  # No NixOS module and no package: pure data plus translators, exposed as a
  # flake lib so features/niri and features/hyprland can pull it in by name.
  flake.lib.keymap = {inherit binds toNiri toHyprlandLua toHyprKey;};
}
