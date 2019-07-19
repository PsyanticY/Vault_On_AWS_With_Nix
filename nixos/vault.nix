{ config, pkgs, ... }:
{
  # datadog monitoring

  # add checks for those systemd units: vault consul client
  # ...
  # ...
  environment.shellInit = ''
    export VAULT_ADDR=http://127.0.0.1:8201
  '';
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 8200 8500 ];
  services.vault.enable = true;
  services.vault.address = "127.0.0.1:8201";
  #services.vault.tlsKeyFile =  "/run/keys/dovah.key";
  #services.vault.tlsCertFile = "/run/keys/dovah.crt";
  services.vault.storageBackend = "consul";
  services.vault.storageConfig = ''
    address = "127.0.0.1:8500"
    path    = "vault/"
  '';
  imports = [ ./consul.nix ./common.nix ];
  services.consulAws.enable = true;
  services.consulAws.server = false;
  services.consulAws.caCertFile = "/run/keys/root.ca";
  services.consulAws.certFile = "/run/keys/dovah.crt";
  services.consulAws.keyFile = "/run/keys/dovah.key";
  services.consulAws.tagKey = "consul-server";
  services.consulAws.tagValue = "consul-server";
 # services.vault.extraConfig = ''
 #   ui = true
 #   listener "tcp" {
 #     address     = "0.0.0.0:8200"
 #     tls_cert_file = "/run/keys/dovah.crt"
 #     tls_key_file  = "/run/keys/dovah.key"
 #     tls_min_version = "tls12"

 #   }

 # '';
  environment.systemPackages = with pkgs; [ vault ];


}
