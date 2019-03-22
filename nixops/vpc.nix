{ region        ? "us-east-1"
, accessKeyId   ? "None"

, vpcTags       ? {}    # should be something like this { foo = "bar"; xyzzy = "bla"; }
, enableTenancy ? false # whether to use dedicated hardware for the vpc.
, supportDns    ? true  # DNS server provided by Amazon is enabled for the VPC ?

, natCidrBlock  ? "10.0.255.240/28"
, natTags       ? {}    # tags specific to the nat subnet
, natAZ         ? "us-east-1c"

, ...
}:
{
  resources.vpc.vaultVpc =
    {
      inherit region accessKeyId;
      tags = vpcTags // {Source = "NixOps";};
      cidrBlock = "10.0.0.0/16";
      instanceTenancy = if enableTenancy then "dedicated" else "default";
      enableDnsSupport = supportDns;
      enableDnsHostnames = supportDns;
    };

  # Recurse this to create 5 EIP for full coverage
  resources.elasticIPs.nat-eip =
    {
      inherit region accessKeyId;
      vpc = true;
    };
    
  resources.vpcSubnets.nat-subnet = 
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.vaultVpc.vpcId;
      cidrBlock = natCidrBlock;
      zone = natAZ;
      tags = {Source = "NixOps"; Type = "NAT Subnet"; VPC = resources.vpc.vaultVpc.vpcId;} // natTags;
    };
  
  resources.vpcNatGateways.nat =
    { resources, ... }:
    {
      inherit region accessKeyId;
      allocationId = resources.elasticIPs.nat-eip;
      subnetId = resources.vpcSubnets.nat-subnet;
    }; 
}
