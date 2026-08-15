{ inputs, ... }: {
  flake.nixosModules.zenBrowser = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
