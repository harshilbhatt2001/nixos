{self, ...}: {
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

    # `nh os switch` (fish's `nrs`): nom build output and an nvd diff before
    # activating, sudo only for the switch. NH_FLAKE points it at this repo.
    # nh's own cleaner stays off; nix.gc above already covers that.
    programs.nh = {
      enable = true;
      flake = "${self.lib.user.home}/.config/nixos";
    };
  };
}
