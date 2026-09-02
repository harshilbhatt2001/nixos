{ pkgs, ... }:

{
  # https://devenv.sh/packages/
  packages = [
    pkgs.claude-code
    pkgs.nixd # Nix language server
  ];

  # See full reference at https://devenv.sh/reference/options/
}
