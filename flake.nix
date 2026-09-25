{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # FIXME: devenv >= 2.3.0 crashes on shell entry ("Shell session error:
    # terminal error: invalid value"), which breaks the fish auto-activation
    # hook. Pinned to the last nixpkgs revision carrying devenv 2.2.2 until
    # https://github.com/cachix/devenv/issues/3183 is fixed; then drop this
    # input and go back to pkgs.devenv in modules/features/devenv.
    #nixpkgs-devenv.url = "github:nixos/nixpkgs/34ab99075ac4f7e40cf037eef32cb1c360bb85e9";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrappers.url = "github:BirdeeHub/nix-wrapper-modules";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland desktop, same sources as the reference: the hyprland input is
    # the reference author's wrapper flake carrying the actual hyprland.lua
    # config (repo-files) and defaultRuntimePkgs; quickshell is a non-flake
    # config repo used as configDir.
    # Own fork of voidarc/hypr (config repo + wrapper flake).
    hyprland.url = "github:harshilbhatt2001/hypr";
    otter-launcher = {
      url = "github:kuokuo123/otter-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Own fork of voidarc/quickshell (non-flake config repo).
    quickshell = {
      url = "github:harshilbhatt2001/quickshell";
      flake = false;
    };
    wshowkeys.url = "github:voidarclabs/wshowkeys";

    # Own neovim config, built by its own flake (nix branch). No nixpkgs
    # follows — it builds against its locked nixpkgs, like the reference.
    nvim.url = "github:harshilbhatt2001/nvim/nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake
    {inherit inputs;}
    (inputs.import-tree ./modules);
}
