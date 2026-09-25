{moduleWithSystem, ...}: {
  # Re-wrap zen so ffmpeg lands on its library path. Firefox dlopens the
  # system libavcodec for H.264/AAC (VP9/AV1/Opus are built in), and nixpkgs'
  # wrapFirefox now keys that on `passthru.withFFmpeg`; the zen-browser flake
  # still sets the old `ffmpegSupport`, so without this override H.264 sites
  # (X, Vimeo, Reddit, most embedded players) play nothing while YouTube
  # works. Drop the override once upstream sets withFFmpeg itself.
  perSystem = {
    pkgs,
    inputs',
    ...
  }: {
    packages.zen-browser = pkgs.wrapFirefox (inputs'.zen-browser.packages.zen-browser-unwrapped.overrideAttrs (o: {
      passthru = o.passthru // {withFFmpeg = true;};
    })) {pname = "zen-browser";};
  };

  flake.nixosModules.zen-browser = moduleWithSystem (
    {self'}: {
      environment.systemPackages = [
        self'.packages.zen-browser
      ];

      environment.sessionVariables.BROWSER = "zen";
      xdg.mime.defaultApplications = {
        "text/html" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
      };
    }
  );
}
