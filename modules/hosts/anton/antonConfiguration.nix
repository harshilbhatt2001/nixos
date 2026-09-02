{...}: {
  # Host-only settings: hostname, this machine's boot chain and disks.
  flake.nixosModules.antonConfiguration = {pkgs, ...}: {
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

    # Gen5 M.2 SSD (slot 1) NTFS data partition (nvme0n1p6), owned by habh
    # so no root is needed to read/write it.
    boot.supportedFilesystems = ["ntfs" "btrfs"];
    fileSystems."/mnt/gen5-ntfs" = {
      device = "/dev/disk/by-uuid/CC1C80041C7FE7BA";
      fsType = "ntfs-3g";
      # dmask/fmask: without them ntfs-3g reports everything as 0777, and
      # ls highlights every entry as executable/other-writable. 755 dirs,
      # 644 files — nothing on here needs a Unix exec bit.
      options = ["rw" "uid=1000" "gid=100" "dmask=022" "fmask=133" "nofail"];
    };

    # Gen5 SSD btrfs data partition (nvme0n1p7).
    fileSystems."/mnt/gen5-btrfs" = {
      device = "/dev/disk/by-label/gen5-btrfs";
      fsType = "btrfs";
      options = ["compress=zstd" "nofail"];
    };

    # ~/ws lives on the btrfs data partition (~/ws-linux is the old
    # on-rootfs one). `L+` so the symlink is retargeted even if one already
    # exists; the `d` rule owns the target dir for habh (fine on btrfs,
    # unlike the NTFS mount where it would warn on every boot).
    systemd.tmpfiles.rules = [
      "d /mnt/gen5-btrfs/ws 0755 habh users -"
      "L+ /home/habh/ws - - - - /mnt/gen5-btrfs/ws"
    ];

    # sbctl: manage/inspect the Secure Boot keys (`sbctl status`, `sbctl verify`).
    environment.systemPackages = with pkgs; [sbctl];
  };
}
