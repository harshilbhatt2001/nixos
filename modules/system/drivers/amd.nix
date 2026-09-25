{...}: {
  # RX 9070 XT (RDNA 4), the primary GPU. Ported from the reference's
  # amdDrivers minus the ROCm compute stack and the ppfeaturemask
  # overclocking unlock — add those deliberately if compute is ever needed.
  # VA-API/VDPAU come with mesa's radeonsi, no extra driver packages.
  flake.nixosModules.amdDrivers = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      vulkan-tools # vulkaninfo, for sanity-checking the driver stack
    ];
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      # Early KMS: amdgpu in the initrd, so the display comes up (and
      # plymouth renders) from the first frames of boot.
      amdgpu.initrd.enable = true;
    };

    # PyTorch (and anything else linking a libdrm that isn't the store one,
    # e.g. the ROCm wheels in ~/ws/comfyui) looks the GPU's marketing name up
    # at the FHS path libdrm was built with, and prints
    # "(null): No such file or directory" plus a generic "AMD Radeon Graphics"
    # when it misses. `L+` retargets the link across libdrm bumps.
    systemd.tmpfiles.rules = [
      "L+ /opt/amdgpu/share/libdrm/amdgpu.ids - - - - ${pkgs.libdrm}/share/libdrm/amdgpu.ids"
    ];
  };
}
