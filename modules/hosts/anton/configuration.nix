{ self, inputs, ... }: {

  flake.nixosModules.antonConfiguration = { config, pkgs, lib, ... }: {
    imports = [
      self.nixosModules.antonHardware
      self.nixosModules.niri
      self.nixosModules.zenBrowser
      self.nixosModules.fish
      self.nixosModules.git
      self.nixosModules.neovim
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

    networking.hostName = "anton";
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Amsterdam";

    i18n.defaultLocale = "en_GB.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_NUMERIC = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_TIME = "nl_NL.UTF-8";
    };

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users."habh" = {
      isNormalUser = true;
      description = "Harshil Bhatt";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [ ];
    };

    programs.firefox.enable = true;

    nixpkgs.config.allowUnfree = true;

    # sbctl: manage/inspect the Secure Boot keys (`sbctl status`, `sbctl verify`).
    environment.systemPackages = with pkgs; [ sbctl ];

    # This value determines the NixOS release from which the default settings
    # for stateful data were taken. Leave it at the release of the first
    # install of this system.
    system.stateVersion = "26.05";
  };

}
