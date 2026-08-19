{ ... }: {
  flake.nixosModules.sudo = { ... }: {
    # One authentication covers every terminal instead of a per-tty
    # timestamp (the timeout itself stays at sudo's default 5 minutes).
    security.sudo.extraConfig = ''
      Defaults !tty_tickets
    '';
  };
}
