{ ... }: {
  flake.nixosModules.git = {
    programs.git.enable = true;

    programs.fish.shellAbbrs = {
      gs = "git status";
      gg = "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an (%ae)%C(reset)' --all";
    };
  };
}
