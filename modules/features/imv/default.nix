{
  inputs,
  moduleWithSystem,
  ...
}: {
  # imv opens files or whole directories (`imv ~/Pictures`, `-r` to recurse);
  # `slideshow DIR [SECONDS]` is the fullscreen, auto-advancing shorthand.
  # In imv, `t` / `T` speed up / slow down a running slideshow (0 = paused).
  flake.nixosModules.imv = moduleWithSystem (
    {self'}: {
      environment.systemPackages = with self'.packages; [
        imv
        slideshow
      ];

      xdg.mime.defaultApplications = builtins.listToAttrs (map (type: {
          name = "image/${type}";
          value = "imv.desktop";
        }) [
          "png"
          "jpeg"
          "gif"
          "webp"
          "avif"
          "heic"
          "bmp"
          "tiff"
          "svg+xml"
        ]);
    }
  );

  perSystem = {
    pkgs,
    lib,
    self',
    ...
  }: {
    packages.imv = inputs.wrappers.wrappers.imv.wrap {
      inherit pkgs;
      settings.options = {
        background = "1e1e2e";
        overlay = true;
        overlay_font = "FiraMono Nerd Font Mono:11";
        overlay_text_color = "cdd6f4";
        overlay_background_color = "181825";
        overlay_background_alpha = "c0";
      };
    };

    packages.slideshow = pkgs.writeShellApplication {
      name = "slideshow";
      runtimeInputs = [pkgs.coreutils pkgs.findutils];
      text = ''
        usage() {
          echo "usage: slideshow [--shuffle] DIR [SECONDS]  (default 5s, recurses into DIR)" >&2
          exit 1
        }
        shuffle=0
        if [ "''${1:-}" = "--shuffle" ] || [ "''${1:-}" = "-s" ]; then
          shuffle=1
          shift
        fi
        [ $# -ge 1 ] && [ $# -le 2 ] && [ -d "$1" ] || usage
        dir="$1"
        secs="''${2:-5}"

        if [ "$shuffle" = 1 ]; then
          # imv reads paths from stdin with `-`; it skips non-images itself.
          find "$dir" -type f | shuf | ${lib.getExe self'.packages.imv} -f -t "$secs" -
        else
          exec ${lib.getExe self'.packages.imv} -f -r -t "$secs" "$dir"
        fi
      '';
    };
  };
}
