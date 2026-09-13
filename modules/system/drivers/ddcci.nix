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
  # If no ddcci* device shows up after a rebuild, the monitor's OSD has a
  # DDC/CI toggle that is sometimes off, and autoprobe on amdgpu can miss the
  # monitor — find the bus with `ddcutil detect`, then
  #   echo 'ddcci 0x37' | sudo tee /sys/bus/i2c/devices/i2c-<N>/new_device
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
  };
}
