{moduleWithSystem, ...}: {
  # `self.lib.installFeature "<name>"` is the NixOS module for a feature whose
  # only job is to install its own package, self'.packages.<name>.
  flake.lib.installFeature = name:
    moduleWithSystem ({self'}: {
      environment.systemPackages = [self'.packages.${name}];
    });
}
