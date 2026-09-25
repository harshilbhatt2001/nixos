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
    # packages.repo-files). Its own inputs follow the system nixpkgs, but NOT
    # hyprwm's Hyprland (inputs.hyprland.inputs.hyprland): that flake only
    # builds against the nixpkgs it pins — following ours pairs its pinned
    # hyprutils with our newer hyprtoolkit, and hyprtoolkit fails to
    # configure. The cost is a mesa older than the system's in the compositor.
    hyprland = {
      url = "github:harshilbhatt2001/hypr";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.otter-launcher.follows = "otter-launcher";
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
