{ config, pkgs, ... }:
{
  # datadog monitoring

  # add checks for those systemd units: vault consul client
  # ...
  # ...
  services.vault.enable = true;
  services.vault.address = "0.0.0.0:8200";
  services.vault.tlsKeyFile = "/etc/keys/dovah.key";
  services.vault.tlsCertFile = "/etc/keys/dovah.crt";
  services.vault.storageBackend = "consul";
  services.vault.storagePath = "/opt/vault/"; ## check it
  services.vault.storageConfig = ''address = "127.0.0.1:8500"'';
  services.vault.extraConfig = ''
    ui = true

    listener "tcp" {
      address     = "127.0.0.1:8201"
      tls_disable = "1"
    }
  '';

  # add consul agent (the nixos implementaion seems retarded)

}