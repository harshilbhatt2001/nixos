{
  lib,
  flake-parts-lib,
  ...
}: {
  # `flake.lib` is assembled from several files (keymap, user, …). Undeclared
  # flake outputs must be defined exactly once, so declare it as a mergeable
  # attrset of raw values.
  options.flake = flake-parts-lib.mkSubmoduleOptions {
    lib = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      default = {};
      description = "Repo-local helpers and data, merged across modules.";
    };
  };

  # flake-parts evaluates `perSystem` once per entry here. With no `systems`,
  # `perSystem` silently produces no outputs and every `self'.packages.*`
  # reference dangles.
  #
  # Linux-only for now: the wrapped desktop packages (hyprland) aren't built for
  # darwin, which would fail `nix flake check` for those systems.
  config = {
    systems = [
      "x86_64-linux"
    ];
  };
}
