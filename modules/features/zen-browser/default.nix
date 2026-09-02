{moduleWithSystem, ...}: {
  flake.nixosModules.zen-browser = moduleWithSystem (
    {inputs'}: {
      environment.systemPackages = [
        inputs'.zen-browser.packages.default
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
