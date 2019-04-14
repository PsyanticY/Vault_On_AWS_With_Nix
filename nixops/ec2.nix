{ allowedGroups  ? []
, region         ? "us-east-1"
, accessKeyId    ? "None"
, rootVolumeSize ? 50
, ...
}:
{
  network.description = "Hashicorp vault";

  defaults = { resources, config, lib, pkgs, ... }:
    {

      deployment.targetEnv = "ec2";
      deployment.ec2.accessKeyId = account;
      deployment.ec2.region = region;
      deployment.ec2.keyPair = resources.ec2KeyPairs.kp;
      deployment.ec2.ebsInitialRootDiskSize = rootVolumeSize;
      deployment.ec2.tags.Deployer = "psyanticy@dovah.com";

      require = [
      ../nixos/users.nix
      ../nixos/common.nix
      ];
      services.ldap.enable = true;
      services.ldap.allowedGroups = allowedGroups;

    };
}