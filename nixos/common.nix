{ config, pkgs, lib, ... }:
{
  networking.timeServers = [];
  time.timeZone = lib.mkOverride 5 "UTC" ;
  environment.systemPackages = with pkgs; [ vim python3 jq awscli tree curl consul];
  environment.shellAliases = { tailf = "tail -f" ;};

  deployment.keys = {
    "dovah.crt".text = builtins.readFile <global_creds/predictix.crt>;
    "dovah.key".text = builtins.readFile <global_creds/predictix.key>;
    "root.ca".text = builtins.readFile <global_creds/digicert.ca>;
    };
  # datadog monitoring
  #services.datadog-agent.enable = true;
  #services.datadog-agent.apiKeyFile = "/etc/keys/datadog_api_key";
  #environment.etc = {
  #  target = "keys/datadog_api_key";
  #  source = <keys/datadog_api_key>;
  #  mode = "0440";
  #};
  # add checks for common important systemd units (sssd, sshd)
  # ...
  # ...
}
