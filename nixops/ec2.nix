{ allowedGroups       ? []
, region              ? "ca-central-1"
, accessKeyId         ? "ops"
, rootVolumeSize      ? 50
, vaultInstanceType   ? "m5.2xlarge"
, fVaultInstanceType  ? "m5.large"
, consulAInstanceType ? "t2.medium"
, consulCInstanceType ? "t2.large"
, consulBInstanceType ? "t3.medium"
, bastionInstanceType ? "t2.micro"
, commonSG            ? "default"
, ...
}:
{
  network.description = "Hashicorp vault";

  defaults = { resources, config, lib, pkgs, ... }:
    {
      deployment.ec2.ami = "ami-0745a8937e0d83eac";
      deployment.targetEnv = "ec2";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.region = region;
      deployment.ec2.keyPair = resources.ec2KeyPairs.kp;
      deployment.ec2.ebsInitialRootDiskSize = rootVolumeSize;
      deployment.ec2.tags.deployer = "psyanticy@dovah.com";

      require = [
      ../nixos/common.nix
      ];

    };

  vault-master = { resources, config, lib, pkgs, name, ... }:
    {

      deployment.ec2.instanceProfile = resources.iamRoles.vault-role.name;
      deployment.ec2.subnetId = resources.vpcSubnets.public-a;
      deployment.ec2.instanceType = vaultInstanceType;
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.vaultSG1.name resources.ec2SecurityGroups.vaultSG2.name resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.elasticIPv4 = resources.elasticIPs.vault-master-eip;
      networking.hostName = "vault-master";

      require = [ ../nixos/vault.nix ];

    };

  vault-failover = { resources, config, lib, pkgs, name, ... }:
    {

      deployment.ec2.instanceProfile = resources.iamRoles.vault-role.name;
      deployment.ec2.subnetId = resources.vpcSubnets.public-c;
      deployment.ec2.instanceType = fVaultInstanceType;
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.vaultSG1.name resources.ec2SecurityGroups.vaultSG2.name resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.elasticIPv4 = resources.elasticIPs.vault-failover-eip;
      networking.hostName = "vault-failover";

      require = [ ../nixos/vault.nix ];

    };

  consul-1 = { resources, config, lib, pkgs, name, ... }:
    {

      # comment those 3 lines if you don't want to use spot/persistent spot
      deployment.ec2.spotInstanceRequestType = "persistent";
      deployment.ec2.spotInstanceInterruptionBehavior = "stop";
      deployment.ec2.spotInstancePrice = 999;
      deployment.ec2.instanceProfile = resources.iamRoles.consul-server-role.name;
      deployment.ec2.subnetId = resources.vpcSubnets.private-a;
      deployment.ec2.instanceType = consulAInstanceType;
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      deployment.ec2.tags.consul-server = "consul-server";
      networking.hostName = "consul-server-a";

      require = [ ../nixos/consul-server.nix ];

    };

  consul-2 = { resources, config, lib, pkgs, name, ... }:
    {

      # comment those 3 lines if you don't want to use spot/persistent spot
      deployment.ec2.spotInstanceRequestType = "persistent";
      deployment.ec2.spotInstanceInterruptionBehavior = "stop";
      deployment.ec2.spotInstancePrice = 999;
      deployment.ec2.instanceProfile = resources.iamRoles.consul-server-role.name;
      deployment.ec2.subnetId = resources.vpcSubnets.private-b;
      deployment.ec2.instanceType = consulBInstanceType;
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      deployment.ec2.tags.consul-server = "consul-server";
      networking.hostName = "consul-server-b";

      require = [ ../nixos/consul-server.nix ];

    };

  consul-3 = { resources, config, lib, pkgs, name, ... }:
    {

      # comment those 3 lines if you don't want to use spot/persistent spot
      deployment.ec2.spotInstanceRequestType = "persistent";
      deployment.ec2.spotInstanceInterruptionBehavior = "stop";
      deployment.ec2.spotInstancePrice = 999;
      deployment.ec2.instanceProfile = resources.iamRoles.consul-server-role.name;
      deployment.ec2.subnetId = resources.vpcSubnets.private-c;
      deployment.ec2.instanceType = consulCInstanceType;
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      deployment.ec2.tags.consul-server = "consul-server";
      networking.hostName = "consul-server-c";

      require = [ ../nixos/consul-server.nix ];

    };

  bastion = { resources, config, lib, pkgs, name, ... }:
    {

      # comment those 3 lines if you don't want to use spot/persistent spot
      deployment.ec2.subnetId = resources.vpcSubnets.public-b;
      deployment.ec2.instanceType = bastionInstanceType;
      deployment.ec2.securityGroupIds = [ commonSG resources.ec2SecurityGroups.vaultInterAccess.name ];
      deployment.ec2.tags.Name = "${config.deployment.name}.${name}";
      networking.hostName = "consul-server-c";
      deployment.ec2.associatePublicIpAddress = true;

      require = [ ../nixos/bastion-server.nix ];

    };
}
