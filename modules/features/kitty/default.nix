{
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.kitty = moduleWithSystem (
    {self'}: {lib, ...}: {
      environment.systemPackages = with self'.packages; [
        kitty
      ];

      # kitten ssh fixes terminfo on the remote and enables kitty's shell
      # integration over ssh.
      programs.fish.shellAbbrs.ssh = "${lib.getExe' self'.packages.kitty "kitten"} ssh";
    }
  );
  perSystem = {pkgs, ...}: {
    packages.kitty = inputs.wrappers.wrappers.kitty.wrap {
      inherit pkgs;
      font = {
        name = "FiraMono Nerd Font Mono";
        size = 11;
      };
      settings = {
        scrollbar = "never";
        pixel_scroll = false;
        window_padding_width = 9;
        background_opacity = 0.50;
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        cursor_trail = 1;
        cursor_trail_start_threshold = 1;
        cursor_trail_color = "#cba6f7";
        cursor_shape = "beam";
        allow_remote_control = true;
      };
      keybindings = {
        "ctrl+backspace" = "send_text all \\x17";
      };
      themeFile = "Catppuccin-Mocha";
    };
  };
}
