{ ... }: {
  # Run unpatched dynamically-linked binaries (vendor tools, pip wheels,
  # vscode-server) without patchelf-ing each one. Library set from the
  # reference; extend it when a binary reports a missing .so.
  flake.nixosModules.nix-ld = { pkgs, ... }: {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        util-linux
        stdenv.cc.cc
        zlib
        libusb1
      ];
    };
  };
}
