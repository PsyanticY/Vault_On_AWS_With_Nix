{ config, pkgs, lib, ...}:

with lib;

let

  cfg = config.services.ldap;

in
{

  options = {

    services.ldap.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable auth via LDAP.
      '';
    };

    services.ldap.allowedGroups =  mkOption {
      default = [];
      type = with types; listOf string;
      description = ''
        The LDAP group name for the users who will access the system.
      '';
    };
  };

  config = mkIf (cfg.enable)
    {

      services.sssd.enable = true;
      services.sssd.sshAuthorizedKeysIntegration = true;
      security.pam.services.sshd.sssdStrictAccess = true;

      security.sudo.extraConfig = ''
        dovah ALL=(ALL) NOPASSWD:ALL
        %fullAccess ALL=(ALL) NOPASSWD:ALL
        ${optionalString (cfg.allowedGroups != []) ''
          ${concatMapStringsSep "\n" (gr: "%"+gr+" ALL=(ALL) NOPASSWD:ALL") cfg.allowedGroups}
          ''}
      '';
      environment.etc."ldap.crt" = {
        target = "keys/ldap.crt";
        source = <keys/ldap.crt>;
        mode = "0440";
      };
      environment.etc."ldap.pem" = {
        target = "keys/ldap.pem";
        source = <keys/ldap.pem>;
        mode = "0440";
      };
      environment.etc."ldap.key" = {
        target = "keys/ldap.key";
        source = <keys/ldap.key>;
        mode = "0440";
      };
      # make sure to ofc update this file
      services.sssd.config = ''
        [domain/default]

        cache_credentials = False
        ldap_search_base = dc=dovah,dc=com
        ldap_uri = ldaps://kin.dovah.com
        ldap_user_search_base = cn=users,cn=accounts,dc=dovah,dc=com

        id_provider = ldap
        auth_provider = ldap
        chpass_provider = ldap

        ldap_user_ssh_public_key = ipaSshPubKey

        # change those if you want to use another path to the keys
        ldap_tls_cert = /etc/keys/ldap.pem
        ldap_tls_key = /etc/keys/ldap.key
        ldap_tls_cacert = /etc/keys/ldap.crt
        ldap_id_use_start_tls = True
        access_provider = simple
        simple_allow_groups = ${concatStringsSep ", " ([ "fullAccess" ] ++ cfg.allowedGroups)}
        simple_allow_users = dovahkin
        override_shell = /run/current-system/sw/bin/bash

        [sssd]

        config_file_version = 2
        services = nss, pam, ssh

        domains = default
        [nss]

        memcache_timeout = 2
        homedir_substring = /home

        [pam]


        [ssh]
      '';
      # backdor user in case ldap is not responding
      users.users.dovah = {
      openssh.authorizedKeys.keys = [ "ssh-rsa xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ];
      useDefaultShell = true;
      createHome = true;
      home = "/home/dovah";
      uid = 900;
    };

    };
}
