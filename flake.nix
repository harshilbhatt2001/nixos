{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland desktop. Both config repos are live-edited out-of-store
    # checkouts (~/.config/hypr, ~/.config/quickshell); these inputs pin the
    # pushed state, which is the fallback config when a checkout is missing
    # (features/hyprland, features/quickshell). Bump them after pushing.
    # Own fork of voidarc/hypr: config repo + wrapper flake (packages.default,
    # packages.repo-files). Everything follows the system nixpkgs, including
    # hyprwm's Hyprland, so its mesa matches the system's; there is no binary
    # cache for it either way.
    hyprland = {
      url = "github:harshilbhatt2001/hypr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.otter-launcher.follows = "otter-launcher";
      inputs.hyprland.inputs.nixpkgs.follows = "nixpkgs";
      inputs.wrappers.inputs.nixpkgs.follows = "nixpkgs";
      inputs.woomer.inputs.nixpkgs.follows = "nixpkgs";
    };
    otter-launcher = {
      url = "github:kuokuo123/otter-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Own fork of voidarc/quickshell (non-flake config repo).
    quickshell = {
      url = "github:harshilbhatt2001/quickshell";
      flake = false;
    };

    # Own neovim config, built by its own flake (nix branch). No nixpkgs
    # follows — it builds against its locked nixpkgs, like the reference —
    # but it shares this repo's wrapper library.
    nvim = {
      url = "github:harshilbhatt2001/nvim/nix";
      inputs.wrappers.follows = "wrappers";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {inherit inputs;}
    (inputs.import-tree ./modules);
}
