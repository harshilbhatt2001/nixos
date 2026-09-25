{...}: {
  # DDC/CI brightness control for external monitors (anton: AOC Q27P2G5 on
  # DP-1 of the 9070 XT). Two layers:
  #  - hardware.i2c: loads i2c-dev and exposes /dev/i2c-* to the i2c group,
  #    which is what `ddcutil detect` / `ddcutil setvcp 10 <n>` need.
  #  - ddcci-driver: out-of-tree kernel module that probes the DDC/CI address
  #    (0x37) on every GPU i2c bus and registers each answering monitor as
  #    /sys/class/backlight/ddcci<bus>. That makes the monitor look like a
  #    laptop panel, so brightnessctl and
  #    way-edges' `backlight` slider (via logind SetBrightness, no root) work
  #    unchanged.
  # The driver cannot autoprobe on kernels >= 6.8 (it logs exactly that), so
  # ddcci-attach instantiates the client by hand: it asks `ddcutil detect`
  # which i2c bus each answering monitor is on and writes `ddcci 0x37` to
  # that bus's new_device. ddcutil, not sysfs, because on amdgpu a DP
  # connector's `ddc` symlink points at the legacy i2c bus ("DM i2c hw bus")
  # while DDC/CI actually travels over the AUX channel ("DM aux hw bus"), and
  # bus numbers are not stable across boots anyway. A udev rule re-runs it on
  # DRM hotplug events.
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
      path = [pkgs.ddcutil pkgs.gnused];
      script = ''
        # "   I2C bus:          /dev/i2c-7" -> "7", one per detected monitor
        ddcutil detect --brief 2>/dev/null \
          | sed -n 's|^ *I2C bus: */dev/i2c-\([0-9]*\)$|\1|p' \
          | while read -r n; do
            # already instantiated (i2c client <bus>-0037 present)
            [ -e "/sys/bus/i2c/devices/$n-0037" ] && continue
            echo "attaching ddcci 0x37 on i2c-$n"
            echo 'ddcci 0x37' > "/sys/bus/i2c/devices/i2c-$n/new_device" || true
          done
      '';
    };

    # re-run on monitor (un)plug; the service is idempotent
    services.udev.extraRules = ''
      ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card[0-9]*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ddcci-attach.service"
    '';
  };
}
