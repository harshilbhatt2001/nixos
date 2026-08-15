{
  # flake-parts evaluates `perSystem` once per entry here. With no `systems`,
  # `perSystem` silently produces no outputs and every `self'.packages.*`
  # reference dangles.
  #
  # Linux-only for now: the wrapped desktop packages (niri) don't evaluate on
  # darwin, which would fail `nix flake check` for those systems.
  config = {
    systems = [
      "x86_64-linux"
    ];
  };
}
