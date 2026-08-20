{ ... }: {
  # Sound with pipewire.
  flake.nixosModules.audio = {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Start pipewire at login instead of waiting for socket activation;
    # without this, a session where no client touches the socket has no
    # audio stack, and bluetoothd refuses A2DP ("Protocol not available").
    systemd.user.services.pipewire.wantedBy = [ "default.target" ];
  };
}
