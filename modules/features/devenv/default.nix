{...}: {
  # Per-project dev environments: `devenv init`, then `devenv allow` once per
  # project to let the hook auto-activate it on cd.
  flake.nixosModules.devenv = {
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages = [pkgs.devenv];

    # The nixpkgs devenv package ships fish completions but no vendor_conf.d
    # hook, so the auto-activation hook has to be sourced explicitly.
    programs.fish.interactiveShellInit = ''
      ${lib.getExe pkgs.devenv} hook fish | source
    '';
  };
}
