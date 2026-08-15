{ self, inputs, ... }: {
  # flake-parts evaluates `perSystem` once per entry. With no `systems`,
  # `perSystem` silently produces no outputs and every `self'.packages.*`
  # reference dangles.
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.anton = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit self inputs; };
    modules = [
      self.nixosModules.antonConfiguration
    ];
  };
}
