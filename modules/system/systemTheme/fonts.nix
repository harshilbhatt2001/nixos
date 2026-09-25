{...}: {
  # System fonts. FiraMono is the UI font (dconf font-name below in
  # cursor.nix, sddm, kitty); JetBrains Mono is hyprlock.conf's $font.
  flake.nixosModules.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs.nerd-fonts; [
      fira-mono
      jetbrains-mono
    ];
  };
}
