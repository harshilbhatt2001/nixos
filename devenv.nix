{pkgs, ...}: {
  # Nix development: nixd LSP (languages.nix) plus formatter and linters that
  # run as git hooks on commit and, through claude.code, after every Claude edit.
  languages.nix.enable = true;

  git-hooks.hooks = {
    alejandra.enable = true; # formatter (the style this repo uses)
    deadnix.enable = true; # unused bindings / lambda args
    statix.enable = true; # anti-pattern linter
    check-merge-conflicts.enable = true;
  };

  packages = with pkgs; [
    nix-output-monitor # nom: readable build output
    nvd # nvd diff <old> <new>: package-level diff between two system closures
    nix-tree # browse what pulls what into a closure
  ];

  # git diff / git show / git log -p via difftastic (structural diffs)
  difftastic.enable = true;

  # Claude Code via devenv's integration rather than the bare package: it
  # writes .claude/settings.json (hooks: git-hooks run after Claude edits a
  # file). The binary itself comes from the system (attrs/development), so
  # nothing unfree is needed here.
  claude.code.enable = true;

  # Colourscheme for the wrapped neovim (features/neovim). init.lua in
  # harshilbhatt2001/nvim reads NVIM_COLORSCHEME at startup and falls back to
  # tomorrow-night when it is unset or unknown. Installed schemes:
  # tomorrow-night, rose-pine, rose-pine-moon, rose-pine-dawn, gruvbox.
  env.NVIM_COLORSCHEME = "gruvbox";

  # The desktop runs from two live-edited checkouts besides this repo; the
  # flake pins their pushed state as the fallback config. Flags anything
  # uncommitted or unpushed in any of the three.
  scripts.desk-status = {
    description = "show uncommitted/unpushed work in this repo, ~/.config/hypr and ~/.config/quickshell";
    exec = ''
      for repo in "$DEVENV_ROOT" "$HOME/.config/hypr" "$HOME/.config/quickshell"; do
        printf '%s: ' "$repo"
        if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
          echo "missing (the flake's pinned copy is in use)"
          continue
        fi
        dirty=$(git -C "$repo" status --porcelain | wc -l)
        ahead=$(git -C "$repo" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo "?")
        if [ "$dirty" = 0 ] && [ "$ahead" = 0 ]; then echo clean; else echo "$dirty changed, $ahead unpushed"; fi
      done
    '';
  };

  scripts.rebuild-diff = {
    description = "build the system closure and show what would change against the running one";
    exec = ''
      desk-status
      nom build ".#nixosConfigurations.$(hostname).config.system.build.toplevel" "$@"
      nvd diff /run/current-system ./result
    '';
  };
}
