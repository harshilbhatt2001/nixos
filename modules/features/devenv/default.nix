{moduleWithSystem, ...}: {
  # Per-project dev environments: `devenv init`, then `devenv allow` once per
  # project to let the hook auto-activate it on cd.
  flake.nixosModules.devenv = moduleWithSystem (
    {inputs'}: {lib, ...}: let
      # FIXME: pkgs.devenv (>= 2.3.0) aborts right after the enterShell tasks
      # with "Shell session error: terminal error: invalid value", so the hook
      # below spawns a shell that dies instantly. 2.3.1 has the same bug.
      # Pinned to devenv 2.2.2 via the nixpkgs-devenv input in flake.nix until
      # https://github.com/cachix/devenv/issues/3183 is fixed; then switch
      # back to pkgs.devenv and drop that input.
      devenv = inputs'.nixpkgs.legacyPackages.devenv;
    in {
      environment.systemPackages = [devenv];

      # The nixpkgs devenv package ships fish completions but no vendor_conf.d
      # hook, so the auto-activation hook has to be sourced explicitly.
      programs.fish.interactiveShellInit = ''
        ${lib.getExe devenv} hook fish | source
      '';
    }
  );
}
