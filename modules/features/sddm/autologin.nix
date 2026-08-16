{...}: {
  # Host-level opt-in (the reference wires it per-host, not into desktop):
  # add `sddm-autologin` to a host's module list to skip the login prompt.
  flake.nixosModules.sddm-autologin = {
    services.displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "habh";
    };
  };
}
