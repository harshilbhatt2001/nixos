{ ... }: {
  # Arrow Lake iGPU: media engine only — the 9070 XT drives the displays.
  # intel-media-driver is the VA-API driver for Broadwell-and-newer; the
  # reference's intel-vaapi-driver is for the pre-Broadwell generations.
  flake.nixosModules.intelDrivers = { pkgs, ... }: {
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
    ];
  };
}
