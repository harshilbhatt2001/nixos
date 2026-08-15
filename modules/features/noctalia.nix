{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs;

      # `settings` is written to settings.json inside the store and pointed at
      # via NOCTALIA_SETTINGS_FILE, so noctalia's own GUI cannot persist edits
      # back. Run `dump-noctalia-shell` to get the live config as Nix and paste
      # the parts you want to keep in here.
      settings = { };
    };
  };
}
