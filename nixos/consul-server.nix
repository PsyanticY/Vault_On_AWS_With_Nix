{ config, pkgs, resources, ... }:
let
  consul-backup = pkgs.writeScriptBin "consul-backup"
    ''
      #!/usr/bin/env bash
      # log function
      log () {
        echo `date +"[%F %T]"` $1
      }

      # usage function
      usage () {
        echo "Usage:"
        echo "    Backup:   $0 --backup"
        echo "    Restore:  $0 --restore <snapshot_s3_object_key>"
        echo
      }

      S3_PREFIX=s3://${resources.s3Buckets.Vault-bucket.name}/backups/
      OBJ_NAME_REGEX=^consul-backup-[0-9]{14}\.snap\.tar$


      ##########
      # backup #
      ##########
      if [[ "$1" = "--backup" ]]; then

        # exit if the current node is not the cluster leader (backup may not be reliable)
        if [[ ! $(consul operator raft list-peers | grep leader | grep $(ip route get 1.2.3.4 | awk '{print $7}')) ]]; then
          echo "[INFO] This node is not the cluster leader. No backup will be created."
          exit 0
        fi;

        SNAP_NAME=consul-backup-`date +%Y%m%d%H%M%S`.snap
        TAR_PATH=$SNAP_NAME.tar

      echo $SNAP_NAME

        log "[INFO] Backup started"
        log "[INFO] Creating consul snapshot..."
        consul snapshot save $SNAP_NAME 2>&1
        if [[ "$?" -ne "0" ]]; then
          log "[ERROR] could not backup keys: 'consul snapshot save' failed. Exiting."
          exit 1
        fi

        log "[INFO] Creating snapshot archive..."
        tar -cvf $TAR_PATH $SNAP_NAME 2>&1
        if [[ "$?" -ne "0" ]]; then
          log "[ERROR] Could not create tar file. Exiting."
          exit 1
        fi

        log "[INFO] Uploading archive file to S3..."
        aws s3 cp $TAR_PATH $S3_PREFIX 2>&1
        if [[ "$?" -ne "0" ]]; then
          log "[ERROR] Could not archive backup archive to S3. Exiting."
          exit 1
        fi


      ###########
      # restore #
      ###########
      elif [[ "$1" = "--restore" ]]; then

        if [[ -z "$2" ]]; then
          usage
          exit 1
        fi;

        if [[ ! "$2" =~ $OBJ_NAME_REGEX ]]; then
          echo "[ERROR] Invalid archive name format."
          exit 1
        fi;

        DOWNLOAD_PATH="./$2"
        echo "[INFO] Donwloading snapshot from S3: $S3_PREFIX$2 to $DOWNLOAD_PATH ..."
        aws s3 cp $S3_PREFIX$2 $DOWNLOAD_PATH 2>&1

        if [[ "$?" -ne "0" ]]; then
          echo "[ERROR] Could not download snapshot from S3"
          exit 1
        fi;

        # extract snapshot
        tar -xvf $DOWNLOAD_PATH 2>&1
        if [[ "$?" -ne "0" ]]; then
          echo "[ERROR] Could not extract snapshot archive."
          exit 1
        fi;

        extracted_file=`echo $2 | sed -e 's/\.tar//g'`

        echo "[INFO] Restoring secrets from snapshot..."
        consul snapshot restore $extracted_file 2>&1
        if [[ "$?" -ne "0" ]]; then
          echo "[ERROR] Failed to load restore from snapshot."
          exit 1
        fi;


      else
        # unknown operation
        usage
        exit 1

      fi;

      echo "[INFO] Done."
      exit 0
  '';
in
{
 imports = [ ./common.nix ./consul.nix ];

  networking.firewall.enable = true;
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

  systemd.services."consul-backup-unit" = {
    description = "backup consul to s3";
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ consul awscli ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      source /etc/profile
      ${consul-backup}/bin/consul-backup --backup
    '';
    # double check this to make sure it is 1 per hour/ use whatever you want
    startAt = "*:00";
  };
}