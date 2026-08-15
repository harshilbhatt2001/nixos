{ ... }: {
  # Host-only settings: hostname, this machine's boot chain and disks.
  flake.nixosModules.antonConfiguration = { pkgs, ... }: {
    networking.hostName = "anton";

    # Bootloader: Limine on the dedicated NixOS ESP (see hardware.nix).
    # Secure Boot chain: firmware verifies the sbctl-signed limine binary,
    # limine verifies its enrolled config, the config's checksums verify the
    # kernels. Keys live in /var/lib/sbctl; they were enrolled with the
    # Microsoft vendor keys kept (`sbctl enroll-keys -m -f`) so Windows on
    # nvme0n1p1 still boots.
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.limine = {
      enable = true;
      maxGenerations = 8;
      secureBoot.enable = true;
      panicOnChecksumMismatch = true;
      # Windows boots from its own ESP (nvme0n1p1); guid() is that
      # partition's PARTUUID.
      extraEntries = ''
        /Windows
          protocol: efi_chainload
          image_path: guid(90f9c4a0-2d03-4b60-8cdb-97096e5d056f):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };

    # "Internal SSD" NTFS data partition (nvme0n1p5), owned by habh so no
    # root is needed to read/write it.
    boot.supportedFilesystems = [ "ntfs" ];
    fileSystems."/mnt/internal-ssd" = {
      device = "/dev/disk/by-uuid/CC1C80041C7FE7BA";
      fsType = "ntfs-3g";
      options = [ "rw" "uid=1000" "gid=100" "nofail" ];
    };

    # sbctl: manage/inspect the Secure Boot keys (`sbctl status`, `sbctl verify`).
    environment.systemPackages = with pkgs; [ sbctl ];

    # Installer leftover, kept until deliberately removed.
    programs.firefox.enable = true;
  };
}
