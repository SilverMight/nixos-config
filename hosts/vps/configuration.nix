{ config, lib, pkgs, inputs, ... }:

let
  format = pkgs.formats.yaml {};
  # A workaround generate a valid Headscale config accepted by Headplane
  settings = lib.recursiveUpdate config.services.headscale.settings {
    tls_cert_path = "/dev/null";
    tls_key_path = "/dev/null";
  };
  headscaleConfig = format.generate "headscale.yml" settings;
in
{
  imports =
    [ 
      ./hardware-configuration.nix
      ./disk-config.nix
      ../../common/default.nix
    ];

  # ==========================================
  # BOOT & SYSTEM
  # ==========================================
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

  # Basic Networking
  networking.hostName = "vps"; 
  networking.domain   = "silvermight.com";
  networking.networkmanager.enable = true; 
  networking.enableIPv6 = true;

  i18n.defaultLocale = "en_US.UTF-8";

  # ==========================================
  # USER & ACCESS
  # ==========================================
  users.users.silvermight = {
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      tree
    ];
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

  environment.variables.EDITOR = "vim";

  environment.systemPackages = with pkgs; [
    vim
    htop
    git
    curl
    tree
  ];

  # ==========================================
  # NETWORKING & FIREWALL
  # ==========================================
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    internalInterfaces = [ "wg0" "tailscale0" ];
    externalInterface = "enp0s6";
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "wg0" "tailscale0" ];
    allowPing = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ 51820 3478 config.services.tailscale.port ];
  };

  # Disable autologin
  services.getty.autologinUser = null;

  # ==========================================
  # SECRETS (SOPS)
  # ==========================================
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."headplane/serverCookieSecret" = {
      owner = "headscale";
      group = "headscale";
      mode = "0440";
    };
    secrets."headplane/headscaleApiKey" = {
      owner = "headscale";
      group = "headscale";
      mode = "0440";
    };
  };

  # ==========================================
  # SERVICES
  # ==========================================

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # Tailscale & Optimizations
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };  
  
  systemd.services.tailscaled.serviceConfig.Environment = [ 
    "TS_DEBUG_FIREWALL_MODE=nftables" 
  ];

  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale-optimizations" = {
      onState = [ "routable" ];
      script = ''
        ${pkgs.ethtool}/bin/ethtool -K enp0s6 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };

  # Headscale (VPN Server)
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

  # Headplane (UI for Headscale)
  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 3000;
        cookie_secret_path = config.sops.secrets."headplane/serverCookieSecret".path;
      };
      headscale = {
        config_path = "${headscaleConfig}";
        api_key_path = config.sops.secrets."headplane/headscaleApiKey".path;
      };
      integration.agent = {
        enabled = true;
      };
    };
  };

  # Web Server & Reverse Proxy
  services.caddy = {
    enable = true;
    virtualHosts."vps.silvermight.com" = {
      extraConfig = ''
        @admin path /admin /admin/*
        
        handle @admin {
          reverse_proxy http://127.0.0.1:3000
        }
        handle {
          reverse_proxy http://127.0.0.1:8080
        }
      '';
    };
  };

  # Minecraft
  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true; 
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
      src = pkgs.fetchurl {
        url = "https://fill-data.papermc.io/v1/objects/74e3a26c32a09dcbb213aec27a107467739e27b12dbe82b1a3e7a4b7d059c730/paper-1.21.10-129.jar";
        sha256 = "0c67b78bg977lfqq5gidn4krwwv7fh87mhmf2frcp7d069na5qvl"; 
      };
    });
  };

  # ==========================================
  # MAINTENANCE
  # ==========================================
  system.stateVersion = "25.05";
}
