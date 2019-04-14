{ config, pkgs, ... }:
{
  networking.timeServers = [];
  time.timeZone = pkgs.lib.mkOverride 4 "Europe/Berlin";
  environment.systemPackages = [ pkgs.vim pkgs.python3 pkgs.jq pkgs.awscli pkgs.tree pkgs.curl ];

  # datadog monitoring
  services.datadog-agent.enable = true;
  services.datadog-agent.apiKeyFile = "/etc/keys/datadog_api_key";
  environment.etc = {
    target = "keys/datadog_api_key";
    source = <keys/datadog_api_key>;
    mode = "0440";
  };
  # add checks for common important systemd units (sssd, sshd)
  # ...
  # ...
}
