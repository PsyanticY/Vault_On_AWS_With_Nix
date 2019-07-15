{ region      ? "ca-central-1"
, accessKeyId ? "ops"
, ...
}:

{
resources.s3Buckets.Vault-bucket = 
  { 
    inherit region accessKeyId;
    name = "vault-bucket123";
    # add rotation policy
  };

resources.ec2SecurityGroups =
  let
    entry = ip:
      {
        fromPort = 8200;
        toPort = 8200;
        sourceIp = if builtins.isString ip then "${ip}/32" else ip;
      };
    vaultSG = name: description: ips:
      {resources, ...}:
      {
        inherit description name region accessKeyId;
        vpcId = resources.vpc.vaultVpc;
        rules = map entry ips;
      };    
  in
  {
    vaultSG1 = vaultSG "vaultSG1" "Security group for incomming 8200 traffic to the vault server" (import ./security-group-ips.nix).sg1;
    vaultSG2 = vaultSG "vaultSG2" "Security group for incomming 8200 traffic to the vault server" (import ./security-group-ips.nix).sg2;
    
    vaultInterAccess = 
      { resources, ...}:
      {
        inherit region accessKeyId;
        vpcId = resources.vpc.vaultVpc;
        name = "vault interaccess";
        description = "security group for interaccess between different vault instances";
        rules = [
          { fromPort = 0; toPort = 65535; sourceIp = "10.0.0.0/16"; }
        ];
      };
  };

resources.iamRoles = 
  {
  consul-server-role =
    { resources, ... }:
    {
      inherit accessKeyId;
      policy = builtins.toJSON
      {
        Statement = [
          {
            Action = [
              "s3:Get*"
              "s3:Put*"
              "s3:List*"
            ];
            Effect = "Allow";
            Resource = [
              "arn:aws:s3:::vault-bucket123"
              "arn:aws:s3:::vault-bucket123/*"
            ];
          } 
          {
            Action = [ "ec2:DescribeInstances" ];
            Resource = "*";
            Effect = "Allow";
          }
        ];
      };
    };

  vault-role =
    { resources, ... }:
    {
      inherit accessKeyId;
      policy = builtins.toJSON
        {
          Statement = 
          {
            Action = [ "ec2:DescribeInstances" ];
            Resource = "*";
            Effect = "Allow";
          };
        };
    };
  };

resources.ec2KeyPairs.kp =
  { 
    inherit region accessKeyId; 
  };
}
