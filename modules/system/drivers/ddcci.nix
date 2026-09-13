{...}: {
  # DDC/CI brightness control for external monitors (anton: AOC Q27P2G5 on
  # DP-1 of the 9070 XT). Two layers:
  #  - hardware.i2c: loads i2c-dev and exposes /dev/i2c-* to the i2c group,
  #    which is what `ddcutil detect` / `ddcutil setvcp 10 <n>` need.
  #  - ddcci-driver: out-of-tree kernel module that probes the DDC/CI address
  #    (0x37) on every GPU i2c bus and registers each answering monitor as
  #    /sys/class/backlight/ddcci<bus>. That makes the monitor look like a
  #    laptop panel, so brightnessctl (the niri brightness keys) and
  #    way-edges' `backlight` slider (via logind SetBrightness, no root) work
  #    unchanged.
  # The driver cannot autoprobe on kernels >= 6.8 (it logs exactly that), so
  # ddcci-attach instantiates the client by hand: for every connected DRM
  # connector it follows the connector's `ddc` symlink to the i2c bus and
  # writes `ddcci 0x37` to that bus's new_device. Bus numbers are not stable
  # across boots (DP-1 was i2c-7, then i2c-2), hence the symlink rather than
  # a fixed number. A udev rule re-runs it on DRM hotplug events.
  # If no ddcci* device shows up anyway, check the monitor's OSD for a DDC/CI
  # toggle, and `ddcutil detect` to see whether the monitor answers at all.
  flake.nixosModules.ddcci = {
    config,
    pkgs,
    ...
  }: {
    hardware.i2c.enable = true;
    boot.extraModulePackages = [config.boot.kernelPackages.ddcci-driver];
    boot.kernelModules = ["ddcci_backlight"];
    users.users."habh".extraGroups = ["i2c"];
    environment.systemPackages = [pkgs.ddcutil];

    systemd.services.ddcci-attach = {
      description = "Attach connected DDC/CI monitors to the ddcci driver";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service" "systemd-udev-settle.service"];
      wants = ["systemd-udev-settle.service"];
      # no RemainAfterExit: the udev rule below re-wants the unit on hotplug,
      # which only re-runs it if it has gone back to inactive
      serviceConfig.Type = "oneshot";
      script = ''
        for conn in /sys/class/drm/card*-*; do
          [ -e "$conn/ddc" ] || continue
          [ "$(cat "$conn/status")" = connected ] || continue
          bus=$(basename "$(readlink -f "$conn/ddc")")
          # already instantiated (i2c client <bus>-0037 present)
          [ -e "/sys/bus/i2c/devices/''${bus#i2c-}-0037" ] && continue
          echo "attaching ddcci 0x37 on $bus ($(basename "$conn"))"
          echo 'ddcci 0x37' > "/sys/bus/i2c/devices/$bus/new_device" || true
        done
      '';
    };

    # re-run on monitor (un)plug; the service is idempotent
    services.udev.extraRules = ''
      ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci-attach.service"
    '';
  };
}
