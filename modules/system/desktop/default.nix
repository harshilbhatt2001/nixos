{self, ...}: {
  # Shared desktop base plus the two selectable desktop-environment groups:
  #  - hyprland     (features/hyprland): the reference's custom DE —
  #                 quickshell, otter-launcher, wlogout, wpaperd…
  #                 It sets services.displayManager.defaultSession, so it is
  #                 the default session at the login screen.
  #  - niriDesktop  (./niri.nix): the pre-hyprland setup, now just niri
  #                 (the legacy installer GNOME + GDM are gone; sddm is the
  #                 display manager for every session).
  # Drop either group here to remove that environment wholesale.
  flake.nixosModules.desktop = {pkgs, ...}: {
    imports = with self.nixosModules; [
      core
      network
      audio
      zen-browser
      kitty
      sddm
      hyprland
      niriDesktop
      way-edges # volume/brightness edge sliders, started by both compositors
      ytmdesktop # Mod+S music scratchpad (features/keymap action `music`)
    ];

    # Plain desktop utilities shared by every session (no wrapping needed).
    environment.systemPackages = with pkgs; [
      brightnessctl # any /sys/class/backlight device, incl. ddcci monitors
    ];

    # Native Wayland for Electron/Chromium apps (ytmdesktop, obsidian, …):
    # nixpkgs' wrappers add the ozone flags only when this is set, otherwise
    # they run under XWayland.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";

    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    hardware.bluetooth.enable = true; # waybar/quickshell bluetooth widgets
    services.upower.enable = true; # quickshell BatteryManager (UPower dbus)
    services.udisks2.enable = true; # removable-drive automount
    # udisks2 mounts removable media freely, but internal partitions (the
    # Windows NTFS ones) need org.freedesktop.udisks2.filesystem-mount-system,
    # which defaults to auth_admin. Let wheel do it without a prompt so file
    # managers work even when no polkit agent is running in the session.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.udisks2.") === 0 &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
    services.gvfs.enable = true; # trash/MTP/network shares in file managers
    services.avahi.enable = true; # network printer discovery for CUPS

    # Secret Service for portals/apps; sddm's PAM hook (features/sddm) unlocks
    # it at login. Pinned here explicitly — it otherwise rides in only via
    # programs.niri's module, and dropping niriDesktop would silently lose it.
    services.gnome.gnome-keyring.enable = true;
  };
}
