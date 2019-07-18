{ config, pkgs, ... }:
{
  # datadog monitoring

  # add checks for those systemd units: vault consul client
  # ...
  # ...
  # we need to set this 
  environment.shellInit = ''
    export VAULT_ADDR=http://127.0.0.1:8201
  '';
  services.vault.address = "127.0.0.1:8201";
  services.vault.enable = true;
  # these options are related to the internal stuff not to the ui
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