{ config, pkgs, ... }:

{
  # flakes on for all
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.settings.trusted-users = [ "root" "silvermight" ];
  
  # Shared User configuration
  users.users.silvermight = {
    isNormalUser = true;
    description = "Joseph";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBR/mDtafM1FvJF7dV/T/G/5NQd9OfR5N4anu2uXGBOg silvermight@silvermight-archlaptop" 
    ];
  };

  # Time zone
  time.timeZone = "America/New_York";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

}
