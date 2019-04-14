{ region        ? "us-east-1"
, accessKeyId   ? "None"

, vpcTags       ? {}    # should be something like this { foo = "bar"; xyzzy = "bla"; }
, enableTenancy ? false # whether to use dedicated hardware for the vpc.
, supportDns    ? true  # DNS server provided by Amazon is enabled for the VPC ?

, natCidrBlock  ? "10.0.255.240/28"
, natTags       ? {}    # tags specific to the nat subnet
, natAZ         ? "us-east-1c"

, subnetTags    ? {}  # should be something like this { foo = "bar"; xyzzy = "bla"; }
, iGWTags       ? {}  # should be something like this { foo = "bar"; xyzzy = "bla"; }

, ...
}:
{
  resources.elasticIPs.nat-eip =
    {
      inherit region accessKeyId;
      vpc = true;
    };
   
  resources.elasticIPs.bastion-eip =
    {
      inherit region accessKeyId;
      vpc = true;
    };
   
  resources.elasticIPs.vault-master-eip =
    {
      inherit region accessKeyId;
      vpc = true;
    };
    
  resources.elasticIPs.vault-failover-eip =
    {
      inherit region accessKeyId;
      vpc = true;
    };
    
  resources.vpc.vaultVpc =
    {
      inherit region accessKeyId;
      tags = vpcTags // {Source = "NixOps";};
      cidrBlock = "10.0.0.0/16";
      instanceTenancy = if enableTenancy then "dedicated" else "default";
      enableDnsSupport = supportDns;
      enableDnsHostnames = supportDns;
    };
    
  resources.vpcInternetGateways.igw =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.vpc.vpcId;
      tags = {Source = "NixOps"; VPC = resources.vpc.vpc;} // iGWTags;
    }; 

  resources.vpcSubnets = 
    let
      subnet = {cidr, zone}:
        { resources, ... }:
        {
          inherit region zone accessKeyId;
          vpcId = resources.vpc.vpc.vpcId;
          cidrBlock = cidr;
          mapPublicIpOnLaunch = false;
          tags = subnetTags // {Source = "NixOps";};
        };
    in
    {
      public-a = subnet { cidr = "10.0.0.0/19"; zone = "us-east-1a"; };
      public-b = subnet { cidr = "10.0.32.0/19"; zone = "us-east-1b"; };
      public-c = subnet { cidr = "10.0.64.0/19"; zone = "us-east-1c"; };
      private-a = subnet { cidr = "10.0.96.0/19"; zone = "us-east-1a"; };
      private-b = subnet { cidr = "10.0.128.0/19"; zone = "us-east-1b"; };
      private-c = subnet { cidr = "10.0.160.0/19"; zone = "us-east-1c"; };
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