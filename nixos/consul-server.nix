{ config, pkgs, ... }:
{
 imports = [ ./common.nix ./consul.nix ];

  networking.firewall.enable = false;
  networking.firewall.allowedTCPPorts = [ 8500 ];

  services.consulAws.enable = true;
  services.consulAws.server = true;
  services.consulAws.caCertFile = "/run/keys/root.ca";
  services.consulAws.certFile = "/run/keys/dovah.crt";
  services.consulAws.keyFile = "/run/keys/dovah.key";
  services.consulAws.tagKey = "consul-server";
  services.consulAws.tagValue = "consul-server";
  services.consulAws.extraConfig = {
    bootstrap_expect = 3;
  };
