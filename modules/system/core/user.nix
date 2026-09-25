{config, ...}: let
  inherit (config.flake.lib) user;
in {
  # The one login user, as flake-level data so NixOS modules and perSystem
  # packages (quickshell's configDir) can both name it: self.lib.user.
  flake.lib.user = {
    name = "habh";
    description = "Harshil Bhatt";
    home = "/home/habh";
  };

  # Define a user account. Don't forget to set a password with `passwd`.
  flake.nixosModules.user = {
    users.users.${user.name} = {
      isNormalUser = true;
      inherit (user) description home;
      extraGroups = ["networkmanager" "wheel"];
    };
  };
}
