{ config, pkgs, lib, ... }:
{
  networking.timeServers = [];
  time.timeZone = lib.mkOverride 5 "UTC" ;
  environment.systemPackages = with pkgs; [ vim python3 jq awscli tree curl consul];
  environment.shellAliases = { tailf = "tail -f" ;};

  # Allowing bastion host to access servers as root
  users.users.root.openssh.authorizedKeys.keyFiles = [ <global_creds/id_rsa.pub> ];

  environment.shellInit = ''
    export EDITOR=vim
    export HISTFILESIZE=50000
    export HISTCONTROL=erasedups
    shopt -s histappend
    export PROMPT_COMMAND="history -a"
    export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%S - '
    export PYTHONDONTWRITEBYTECODE=1
  '';
  programs.bash.enableCompletion = true;
  security.pam.enableSSHAgentAuth = true;
  users.motd = ''
      ===###===###===###===###===###===###===###===###===###===###===###===


                  ____                  _       _  ___
                 |  _ \  _____   ____ _| |__   | |/ (_)_ __
                 | | | |/ _ \ \ / / _` | '_ \  | ' /| | '_ \
                 | |_| | (_) \ V / (_| | | | | | . \| | | | |
                 |____/ \___/ \_/ \__,_|_| |_| |_|\_\_|_| |_|

                 Dovahkiin, Dovahkiin, naal ok zin los vahriin
                     Wah dein vokul mahfaeraak ahst vaal!
              Ahrk fin norok paal graan fod nust hon zindro zaan
                     Dovahkiin, fah hin kogaan mu draal!

      ===###===###===###===###===###===###===###===###===###===###===###===

    '';

  deployment.keys = {
    "dovah.crt".text = builtins.readFile <global_creds/dovah.crt>;
    "dovah.key".text = builtins.readFile <global_creds/dovah.key>;
    "root.ca".text = builtins.readFile <global_creds/root.ca>;
    };
}
