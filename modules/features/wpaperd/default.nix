{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.nixosModules.wpaperd = moduleWithSystem ({self', ...}: {
    environment.systemPackages = with self'.packages; [
      wpaperd
    ];
  });
  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    # fzf over the store wallpapers dir (kitty icat preview), then repoint the
    # running daemon. Session-only: the baked config below is what wpaperd
    # boots with, so a reboot goes back to random-from-dir.
    packages.wallpaper-picker = pkgs.writeShellApplication {
      name = "wallpaper-picker";
      # SC2016: the single-quoted ''${FZF_*} vars are expanded by fzf, not the shell
      excludeShellChecks = ["SC2016"];
      text = ''
        sel="$(find ${./wallpapers} -type f | sort | ${lib.getExe pkgs.fzf} \
          --delimiter=/ --with-nth=-1 \
          --with-shell '${lib.getExe pkgs.bash} -c' \
          --preview '${lib.getExe pkgs.kitty} +kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=''${FZF_PREVIEW_COLUMNS}x''${FZF_PREVIEW_LINES}@0x0 {}')" || exit 0
        [ -n "$sel" ] || exit 0
        ${pkgs.wpaperd}/bin/wpaperctl set-wallpaper "$sel"
      '';
    };

    packages.wpaperd = let
      config-file = builtins.toFile "config.toml" ''
        [any]
        path = "${./wallpapers}"

        [HDMI-A-1]
        path = "${./wallpapers/topo1.png}"

        [DP-1]
        path = "${./wallpapers/topo2.png}"

        [DP-2]
        path = "${./wallpapers/topo3.png}"
      '';
    in
      inputs.wrappers.lib.wrapPackage ({...}: {
        inherit pkgs;
        package = pkgs.wpaperd;
        flags = {
          "--config" = config-file;
        };
      });
  };
}
