{ config, pkgs, lib, ...}:

with lib;

let

  cfg = config.services.consulAws;
  configOptions = {
    data_dir = cfg.dataDir;
    ui = cfg.webUi;
    server = cfg.server;
    client_addr = "0.0.0.0";
    key_file = cfg.keyFile;
    cert_file = cfg.certFile;
    ca_file = cfg.caCertFile;
    verify_incoming = true;
    verify_outgoing = true;
    retry_join = [
      "provider=aws tag_key=${cfg.tagKey} tag_value=${cfg.tagValue}"
    ];
    
  };
in
{

  options = {
    services.consulAws = {
      enable = mkEnableOption "Consul daemon";
    
      server =  mkOption {
        default = true;
        type = with types; bool;
        description = ''
          Whether to run consul in server or agent mode.
        '';
      };

      caCertFile = mkOption {
        type = types.str;
        description = ''
          ca certificate file.
        '';
      };
      certFile = mkOption {
        type = types.str;
        description = ''
          certificate file.
        '';
      };
      keyFile = mkOption {
        type = types.str;
        description = ''
          key certificate file.
        '';
      };
      
      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/consul";
        description = ''
          consul data dir
        '';
      };

      webUi = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables the web interface on the consul http port.
        '';
      };
      tagKey = mkOption {
        type = types.str;
        description = ''
          tag key consul use to get other consul servers
        '';
      };
      tagValue = mkOption {
        type = types.str;
        description = ''
          tag value consul use to get other consul servers
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    
     environment = {
        etc."consul.json".text = builtins.toJSON configOptions;
        # We need consul.d to exist for consul to start
        etc."consul.d/consul.json".text = builtins.toJSON configOptions;
        systemPackages = [ pkgs.consul ];
      };
     systemd.services.consul = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        restartTriggers = [ config.environment.etc."consul.d/consul.json".source ];
        serviceConfig = {
          ExecStart = "@${pkgs.consul.bin}/bin/consul consul agent -config-dir /etc/consul.d";
          ExecReload = "${pkgs.consul.bin}/bin/consul reload";
          Restart = "on-failure";
          TimeoutStartSec = "infinity";
        };
        path = with pkgs; [ iproute gnugrep gawk consul ];
      };
   };
}
