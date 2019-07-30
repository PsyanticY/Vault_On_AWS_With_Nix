{ config, pkgs, lib, ... }:
let
# find a way to dynamically put hostnames
  consul-keys-copy = pkgs.writeScriptBin "consul-keys-copy" ''
        #!/usr/bin/env bash

    # log function
        log () {
          echo `date +"[%F %T]"` $1
        }

    for i in consul-1 consul-2 consul-3
    do
        ssh $i "test -e /run/keys/done"
        if  [[ "$?" ==  "1" ]]; then
          log "[WANING]: No keys found in $i /run/keys, copying new keys ..."
          scp -pr /run/keys/* $i:/run/keys
          log "[INFO]: Restarting multi-user.target ..."
          ssh $i "systemctl restart multi-user.target"
        else
          log "[INFO]: All good ..."
        fi

    done
      '';
  consul-spot-check = pkgs.writeScriptBin "consul-spot-check" ''
    #!/usr/bin/env bash

    # log function
        log () {
          echo `date +"[%F %T]"` $1
        }

    SERVER_DOWN=0
    SSHD_PORT=22
    CONSUL_PORT=8500
    TIMEOUT=300
    # check if we can dynamically get these names
    for i in consul-1 consul-2 consul-3
    do
        # we check consul instance via the sshd (22) and consul server (8500) ports
        # if only one of them time out we assume that the server is under some load or not responsive
        # if both time out the the server is for sure down.
        nc -z -$TIMEOUT $i $SSHD_PORT 2>/dev/null
        if  [[ "$?" ==  "1" ]]; then
          nc -z -$TIMEOUT $i $CONSUL_PORT 2>/dev/null
          if [[ "$?" == "1" ]]; then
             log "[ERROR]: Can't reach $i via $SSHD_PORT or $CONSUL_PORT"
             log "[ERROR]: $i is down"
             SERVER_DOWN=$((SERVER_DOWN+1))
          else
             log "[WARNING]: Can't reach $i via $CONSUL_PORT"
          fi
        else
          nc -z -$TIMEOUT $i $CONSUL_PORT 2>/dev/null
            if [[ "$?" == "1" ]]; then
               log "[WARNING]: Can't reach $i via $CONSUL_PORT"
            else
               log "[INFO]: $i is all good"
            fi
        fi
    done
    if [[ $SERVER_DOWN -eq 2 ]]; then
        log "[ERROR] 2 out of the 3 spot consul backend instances are down. Do your thing ..."
        exit 1
    fi

      '';
in {
  imports = [ ./common.nix ];
  deployment.keys."id_rsa".text = builtins.readFile <global_creds/id_rsa>;
  deployment.keys."id_rsa.pub".text = builtins.readFile <global_creds/id_rsa.pub>;
  systemd.services."ssh-keys" = {
    description = "SSH keys";
    wantedBy = [ "multi-user.target" ];
    after = [ "nixops-keys.target" ];
    script = ''
      mkdir -p /root/.ssh
      mv /run/keys/id_rsa /root/.ssh/
      cp /run/keys/id_rsa.pub /root/.ssh/
      chmod 700 /root/.ssh
      chmod 600 /root/.ssh/id_rsa
      chmod 600 /root/.ssh/id_rsa.pub
      chown -R root:root /root/.ssh
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
  systemd.services."consul-spot-check" = {
    description = "check whether the consul spot instances are available";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    script = ''
      source /etc/profile
      ${consul-spot-check}/bin/consul-spot-check --backup
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };
  systemd.timers."consul-spot-check" = {
    description = "check whether the consul spot instances are available";
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    timerConfig.OnActiveSec = "10m";
    timerConfig.OnUnitActiveSec = "10m";
  };

  systemd.services."consul-keys-check" = {
    description = "copy keys to spot instances recently spinned up";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    script = ''
      source /etc/profile
      ${consul-keys-check}/bin/consul-keys-check
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
  };
  systemd.timers."consul-keys-check" = {
    description = "copy keys to spot instances recently spinned up";
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    timerConfig.OnActiveSec = "15m";
    timerConfig.OnUnitActiveSec = "15m";
  };
}

