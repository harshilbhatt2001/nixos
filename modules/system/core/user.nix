{ ... }: {
  # Define a user account. Don't forget to set a password with `passwd`.
  flake.nixosModules.user = {
    users.users."habh" = {
      isNormalUser = true;
      description = "Harshil Bhatt";
      extraGroups = [ "networkmanager" "wheel" ];
    };
  };
}
