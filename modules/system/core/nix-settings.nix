{self, ...}: {
  flake.nixosModules.nix-settings = {pkgs, ...}: {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;

    # Hard-linking identical store files.
    nix.optimise.automatic = true;

    # `nh os switch` (fish's `nrs`): nom build output and an nvd diff before
    # activating, sudo only for the switch. NH_FLAKE points it at this repo.
    programs.nh = {
      enable = true;
      flake = "${self.lib.user.home}/.config/nixos";
      # Besides old generations, ages out result links and .direnv roots.
      # devenv's .devenv/gc roots stay as long as their project exists; only
      # orphaned ones go. --keep 5 is a floor in case the machine sat unused
      # for two weeks; Limine lists the newest 8 generations anyway
      # (hosts/anton).
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep-since 14d --keep 5";
      };
    };

    # `nom build` / `nom develop` / `nom shell`: nix's commands with nom's
    # build tree, for everything nh doesn't cover (fish abbr: nb).
    environment.systemPackages = [pkgs.nix-output-monitor];
  };
}
