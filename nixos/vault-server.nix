{ config, pkgs, ... }:
let
  vault-bin = with pkgs; stdenv.mkDerivation rec {
    name = "vault-${version}";
    version = "1.1.3";

    src = fetchurl {
      url = "https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip";
      sha256 = "293b88f4d31f6bcdcc8b508eccb7b856a0423270adebfa0f52f04144c5a22ae0";
    };

    buildInputs = [ unzip ];

    buildCommand = ''
      mkdir -p $out/bin $out/share/bash-completion/completions
      unzip $src
      mv vault $out/bin
      echo "complete -C $out/bin/vault vault" > $out/share/bash-completion/completions/vault
    '';
  };
in
{
  environment.shellInit = ''
    export VAULT_ADDR=http://127.0.0.1:8201
  '';
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 8200 8500 ];
  systemd.services.vault.serviceConfig = {
    User = builtins.mkForce null;
    Group = builtins.mkForce null;
  };
  services.vault.enable = true;
  services.vault.package = vault-bin;
  services.vault.address = "127.0.0.1:8201";
  services.vault.storageBackend = "consul";
  services.vault.storageConfig = ''
    address = "127.0.0.1:8500"
    path    = "vault/"
  '';
  services.vault.extraConfig = ''
    ui = true
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_cert_file = "/run/keys/predictix.crt"
      tls_key_file  = "/run/keys/predictix.key"
      tls_min_version = "tls12"

    }
  '';

  imports = [ ./consul.nix ./common.nix ];
  services.consulAws.enable = true;
  services.consulAws.server = false;
  services.consulAws.caCertFile = "/run/keys/root.ca";
  services.consulAws.certFile = "/run/keys/dovah.crt";
  services.consulAws.keyFile = "/run/keys/dovah.key";
  services.consulAws.tagKey = "consul-server";
  services.consulAws.tagValue = "consul-server";

  environment.systemPackages = with pkgs; [ vault-bin ];

}