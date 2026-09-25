{moduleWithSystem, ...}: {
  # Installed directly rather than through programs.neovim, which would
  # re-wrap the already-wrapped nvim (provider-disable flags, an extra
  # wrapper layer). The inner wrapper (the `nvim` input) already puts
  # wl-clipboard on nvim's PATH via runtimePkgs, so the clipboard needs
  # nothing here.
  flake.nixosModules.neovim = moduleWithSystem (
    {self'}: {
      environment.systemPackages = [self'.packages.neovim];
      # what programs.neovim.defaultEditor set (sessionVariables, so it also
      # reaches PAM/non-shell sessions)
      environment.sessionVariables.EDITOR = "nvim";
    }
  );

  perSystem = {inputs', ...}: {
    packages.neovim = inputs'.nvim.packages.default;
  };
}
