{ inputs, moduleWithSystem, ... }:
let
  # Shared between programs.fish (the system carrier below) and the
  # standalone wrapped package in perSystem, so the two can't drift.
  fishConfig = { pkgs, lib, self' }: {
    interactiveShellInit = ''
      # carapace: completions for commands fish has none for
      set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
      ${lib.getExe pkgs.carapace} _carapace | source

      # fzf keybindings: Ctrl-T files, Ctrl-R history, Alt-C cd
      ${lib.getExe pkgs.fzf} --fish | source

      # stay in fish inside nix-shell / nix shell
      ${lib.getExe pkgs.any-nix-shell} fish --info-right | source

      # zoxide: `z <dir>` frecency jumps, `zi` interactive via fzf
      ${lib.getExe pkgs.zoxide} init fish | source

      # devenv: auto-activate allowed projects on cd. Lives here, not in
      # features/devenv, so the standalone wrapped fish gets it too - its
      # --no-config drops every programs.fish extension.
      ${lib.getExe pkgs.devenv} hook fish | source

      # prompt last: its right prompt wins over any-nix-shell's, and the
      # nix-shell/devshell indicators live in config.toml instead
      ${lib.getExe self'.packages.ohMyPosh} init fish | source
    '';

    shellAliases = {
      ls = "${lib.getExe pkgs.lsd} -l";
      cat = lib.getExe pkgs.bat;
      # single quotes: the fish wrapper emits `alias name="value"` verbatim,
      # so a double quote inside the value would terminate it early
      man = "man -P '${lib.getExe pkgs.bat} -p'";
      v = lib.getExe self'.packages.neovim;
      lg = lib.getExe self'.packages.lazygit;
    };

    shellAbbrs = {
      nsh = "nix-shell -p";
      # The reference derives the flake path from $PWD at build time,
      # which needs --impure; this repo lives at a fixed path instead.
      nrs = "sudo nixos-rebuild switch --flake ~/.config/nixos";
      vinix = "nvim ~/.config/nixos";
    };
  };
in {
  # Port of the reference's zsh feature. What zsh needed plugins for
  # (autosuggestions, syntax highlighting, completion, history search,
  # word-wise editing) fish does natively, so only the tool integrations
  # and aliases carry over. The reference bakes everything into a wrapped
  # shell; here programs.fish stays the carrier because features/kitty and
  # features/devenv already extend it, and a `--no-config` wrapped fish
  # would silently drop their snippets along with NixOS login-env sourcing.
  flake.nixosModules.fish = moduleWithSystem (
    { self' }:
    { pkgs, lib, ... }:
    let
      cfg = fishConfig { inherit pkgs lib self'; };
    in {
      programs.fish = {
        enable = true;
        inherit (cfg) interactiveShellInit shellAliases shellAbbrs;
      };

      # also useful standalone, not just inside the sourced snippets
      environment.systemPackages = with pkgs; [
        bat
        carapace
        fzf
        lsd
        zoxide
        # `bass <bash command>` runs it in bash and imports the env changes;
        # ships a vendor function that programs.fish autoloads from here
        fishPlugins.bass
      ];

      users.defaultUserShell = pkgs.fish;
    }
  );

  perSystem = { pkgs, lib, self', ... }:
    let
      cfg = fishConfig { inherit pkgs lib self'; };
    in {
      packages.ohMyPosh = inputs.wrappers.wrappers.oh-my-posh.wrap {
        inherit pkgs;
        configFile = ./config.toml;
      };

      # standalone `nix run .#fish`: same config as the system shell, minus
      # the programs.fish extensions other features contribute on anton
      packages.fish = inputs.wrappers.wrappers.fish.wrap {
        inherit pkgs;
        # The module defaults --no-config to true, which skips fish's stock
        # init along with user dotfiles: fish_complete_path collapses to one
        # entry and theme / universal-variable loading is skipped (issue #1).
        # Sourcing $__fish_data_dir/config.fish by hand is not an option:
        # nixpkgs fish 4.8 embeds its data files, nothing exists on disk.
        flags."--no-config" = false;
        # carapace's generated completers call bare `carapace` from PATH. The
        # NixOS side gets it from environment.systemPackages; the standalone
        # wrapper has to bring it along itself.
        runtimePkgs = [ { data = pkgs.carapace; prefix = true; } ];
        # The wrapper injects this into every fish invocation, interactive or
        # not; programs.fish guards it on NixOS. Without the guard, carapace's
        # fish bridge (a non-interactive `fish --no-config -c ...` that is this
        # wrapper again) re-runs the init and recurses forever on a cold
        # ~/.cache/carapace cache.
        configFile.content = ''
          if status is-interactive
          ${cfg.interactiveShellInit}
          end
        '';
        shellAliases = cfg.shellAliases;
        abbreviations = cfg.shellAbbrs;
        plugins = [ pkgs.fishPlugins.bass ];
      };
    };
}
