# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./disk-config.nix
    ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd.systemd.enable = true;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };

  };

  networking.hostName = "vps"; # Define your hostname.
  networking.domain   = "silvermight.com";
  # Pick only one of the below networking options.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.enableIPv6 = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.silvermight = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBR/mDtafM1FvJF7dV/T/G/5NQd9OfR5N4anu2uXGBOg"];
  };

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
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
    ethtool
    htop
  ];

  environment.variables.EDITOR = "vim";


  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # enable NAT
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "wg0" "tailscale0" ];
    externalInterface = "eth0";
  };

  networking.firewall.trustedInterfaces = [ "wg0" "tailscale0" ];
  networking.firewall.allowPing = true;

  #  networking.wireguard.interfaces = {
  #    # "wg0" is the network interface name. You can name the interface arbitrarily.
  #    wg0 = {
  #      # Determines the IP address and subnet of the server's end of the tunnel interface.
  #      ips = [ "10.0.0.1/24" ];
  #
  #      # The port that WireGuard listens to. Must be accessible by the client.
  #      listenPort = 51820;
  #
  #      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
  #      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
  #      postSetup = ''
  #        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
  #
  #        # Allow LAN traffic between WireGuard clients
  #        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT
  #        '';
  #
  #      # This undoes the above command
  #      postShutdown = ''
  #        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
  #
  #        # Remove LAN forwarding
  #        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o wg0 -j ACCEPT
  #        '';
  #
  #      privateKey = "eHiWQzIb6eDTDasUCZS4xA2rwGvvKY/Vqxr11VAAfnM=";
  #
  #      peers = [
  #        # List of allowed peers.
  #        { # PC
  #          publicKey = "URAuDqJwRzVCl/kj4IiVZHpbhxoOLX5EgN4eWHsxh1M=";
  #          allowedIPs = [ "10.0.0.2/32" ];
  #        }
  #        { # Phone
  #          publicKey = "RVMtYKUkZoJkzvFYJvE5dBaVDC9DukpL5Spe8vpj4nE=";
  #          allowedIPs = [ "10.0.0.3/32" ];
  #        }
  #        {
  #          # Router
  #          publicKey = "disQThor/fCCQOwZX/cYC2DJueodK2AnM6pCpUia52k=";
  #          allowedIPs = [ "10.0.0.4/32" "192.168.1.0/24" ];
  #        }
  #      ];
  #    };
  #  };
  # Disable autologin
  services.getty.autologinUser = null;
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.firewall.allowedUDPPorts = [ 51820 3478 config.services.tailscale.port ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?



  # Minecraft
  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true; # Opens the port the server is running on (by default 25565 but in this case 43000)
    declarative = true;
    whitelist = {
      SilverMight = "74e44e47-3773-4de7-9559-3d68525b11b4";
      TyMotor = "eb033975-e786-4f28-80d0-3e0f2fcd02f9";
      BillNye66 = "93b315bb-b52b-47cc-887d-a303f66f4f8b";
      LarrgeUziVert = "5d8a8fcb-3b7b-43ef-9428-80782608353e";
    };
    serverProperties = {
      difficulty = 3;
      gamemode = 0;
      max-players = 5;
      motd = "A Minecraft Server";
      white-list = true;
    };
    jvmOpts = "-Xms10G -Xmx10G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
    package = pkgs.papermc.overrideAttrs (old: rec {
      version = "1.21.10"; 

      # Paste the URL and the Hash you got in Step 1
      src = pkgs.fetchurl {
        url = "https://fill-data.papermc.io/v1/objects/74e3a26c32a09dcbb213aec27a107467739e27b12dbe82b1a3e7a4b7d059c730/paper-1.21.10-129.jar";
        sha256 = "0c67b78bg977lfqq5gidn4krwwv7fh87mhmf2frcp7d069na5qvl"; 
      };
    });
  };

  services.nginx.enable = false;
  services.nginx.virtualHosts."vps.silvermight.com" = {
    root = "/var/www/vps.silvermight.com";
  };

  services.headscale = {
    enable = true;
    port = 8080;
    address = "127.0.0.1";

    settings = {
      server_url = "https://vps.silvermight.com"; 
      noise.private_key_path = "/var/lib/headscale/noise_private.key";

      dns = {
        base_domain = "ts.silvermight.com"; 
        magic_dns = true;
        nameservers.global = [ "192.168.1.1" ];
      };

      # EMBEDDED DERP SERVER CONFIGURATION
      derp.server = {
        enabled = true;
        region_id = 999;
        region_code = "my-derp";
        region_name = "My Embedded DERP";
        stun_listen_addr = "[::]:3478";

        ipv4 = "132.145.204.148";
        ipv6 = "2603:c020:401d:bc12:0:452b:dac6:b901";
      };

      derp.urls = []; 
    };
  };


  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };  
  # This avoids the "iptables-compat" translation layer issues.
  systemd.services.tailscaled.serviceConfig.Environment = [ 
    "TS_DEBUG_FIREWALL_MODE=nftables" 
  ];

  services.caddy = {
    enable = true;
    virtualHosts."vps.silvermight.com" = {
      extraConfig = ''
            handle {
              reverse_proxy http://127.0.0.1:8080
            }
      '';
    };
  };

  services.networkd-dispatcher = {
  enable = true;
  rules."50-tailscale-optimizations" = {
    onState = [ "routable" ];
    script = ''
      ${pkgs.ethtool}/bin/ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off
    '';
  };
};
}

