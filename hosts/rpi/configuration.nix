{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../common/default.nix
    ];

  # ==========================================
  # 1. BOOT & SYSTEM
  # ==========================================
  # extlinux for PI
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Basic Networking
  networking.hostName = "rpi"; 
  networking.networkmanager.enable = true;
  
  # PROPRIETARY HARDWARE BULLSHIT
  # Enable the Raspberry Pi firmware and drivers
  hardware.enableRedistributableFirmware = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

  # ==========================================
  # USER & ACCESS (Specifics only)
  # ==========================================
  users.users.silvermight = {
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # no sudo passwd
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraRules = [
    {
      users = ["silvermight"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  ## PACKAGES (Specific to RPi)
  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    curl
    tree
    libraspberrypi
    nfs-utils
    cryptsetup
    btrfs-progs
    smartmontools
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2049 2283 ]; # SSH & NFS
    allowedUDPPorts = [ 2049 ];    # NFS
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # ==========================================
  # FILESYSTEMS
  # ==========================================

  # These are on an external drive that I don't want automounted, must cryptsetup when needed; 
  # this just helps mount points be available for NFS, and options
  fileSystems."/mnt/backup" = {
    device = "/dev/mapper/backup";
    fsType = "btrfs"; 
    options = [ "noauto" "nofail" "noatime" "compress=zstd" ];
  }; 

  fileSystems."/mnt/meme" = {
    device = "/dev/mapper/meme"; 
    fsType = "btrfs"; 
    options = [ "noauto" "nofail" "user" "noatime" "compress=zstd" ];
  };

  # ==========================================
  #  SERVICES
  # ==========================================
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /mnt/backup joey-archlinuxpc.lan(rw,nohide,insecure,no_subtree_check,no_root_squash,crossmnt)
    /mnt/meme  joey-archlinuxpc.lan(rw,async,all_squash,anonuid=1001,anongid=100,no_subtree_check)
  '';

  # Smartmondaemon 
  services.smartd = {
    enable = true;
    autodetect = true; 
    defaults.autodetected = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../7/04)";
    notifications.wall.enable = true;
  };

  # Borg hosting
  services.borgbackup.repos = {
      borgRepo = {
        path = "/mnt/backup/borg";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICVISoOZI3rWLfDH6wTADb4Q1G2i3vKukozEkRwa2oD3 borg-backup-key"
        ];
      };
    };

  virtualisation.docker.enable = true;
  
  # ==========================================
  # MAINTENANCE
  # ==========================================
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "25.11"; 
}
