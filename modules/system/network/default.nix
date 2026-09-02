{...}: {
  flake.nixosModules.network = {
    networking.networkmanager.enable = true;

    # Blocks boot for up to 30s waiting for an address; nothing here needs
    # network-online.target, so skip it (as the reference does).
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
