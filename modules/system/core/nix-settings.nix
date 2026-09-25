{...}: {
  flake.nixosModules.nix-settings = {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;

    # Weekly GC of generations older than two weeks, plus hard-linking
    # identical store files. Limine only lists the newest 8 generations
    # anyway (hosts/anton).
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    nix.optimise.automatic = true;
  };
}
