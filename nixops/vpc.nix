{ region        ? "ca-central-1"
, accessKeyId   ? "ops"

, vpcTags       ? {}    # should be something like this { foo = "bar"; xyzzy = "bla"; }
, enableTenancy ? false # whether to use dedicated hardware for the vpc.
, supportDns    ? true  # DNS server provided by Amazon is enabled for the VPC ?

, natCidrBlock  ? "10.0.255.240/28"
, natTags       ? {}    # tags specific to the nat subnet
, natAZ         ? "ca-central-1a"

, subnetTags    ? {}  # should be something like this { foo = "bar"; xyzzy = "bla"; }
, iGWTags       ? {}  # should be something like this { foo = "bar"; xyzzy = "bla"; }

, ...
}:
with (import <nixpkgs> {}).lib;
{
  resources.elasticIPs = 
    let
      eip = 
        {
          inherit region accessKeyId;
          vpc = true;
          # uncomment when this feature get merged
          # persistOnDestroy = true;
        };
    in
      {
        nat-eip = eip;
        bastion-eip = eip;
        vault-failover-eip = eip;
        vault-master-eip = eip;
      };
    
  resources.vpc.vaultVpc =
    {name, ...}:
    {
      inherit region accessKeyId;
      tags = vpcTags // {Source = "NixOps"; Name = "${name}";};
      cidrBlock = "10.0.0.0/16";
      instanceTenancy = if enableTenancy then "dedicated" else "default";
      enableDnsSupport = supportDns;
      enableDnsHostnames = supportDns;
    };
    
  resources.vpcInternetGateways.igw =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.vaultVpc;
      tags = {Source = "NixOps"; Name = "${name}";} // iGWTags;
    };

  resources.vpcNatGateways.nat =
    { resources, ... }:
    {
      inherit region accessKeyId;
      allocationId = resources.elasticIPs.nat-eip;
      subnetId = resources.vpcSubnets.nat-subnet;
      tags = {Source = "NixOps"; Name = "${name}";} // natTags;
    };

  resources.vpcSubnets = 
    let
      subnet = {cidr, zone}:
        { resources, name, ... }:
        {
          inherit region zone accessKeyId;
          vpcId = resources.vpc.vaultVpc;
          cidrBlock = cidr;
          mapPublicIpOnLaunch = false;
          tags = subnetTags // {Source = "NixOps"; Name = "${name}";};
        };
    in
    {
      public-a = subnet { cidr = "10.0.0.0/19"; zone = "ca-central-1a"; };
      public-b = subnet { cidr = "10.0.32.0/19"; zone = "ca-central-1b"; };
      public-c = subnet { cidr = "10.0.64.0/19"; zone = "ca-central-1a"; };
      private-a = subnet { cidr = "10.0.96.0/19"; zone = "ca-central-1b"; };
      private-b = subnet { cidr = "10.0.128.0/19"; zone = "ca-central-1a"; };
      private-c = subnet { cidr = "10.0.160.0/19"; zone = "ca-central-1b"; };
      
      nat-subnet = 
       { resources, ... }:
       {
         inherit region accessKeyId;
         vpcId = resources.vpc.vaultVpc;
         cidrBlock = natCidrBlock;
         zone = natAZ;
         tags = {Source = "NixOps"; Name = "${name}";} // natTags;
       };
     };

  resources.vpcRouteTables =
    let
      route = 
      { resources, name, ... }:
      {
        inherit region accessKeyId;
        vpcId = resources.vpc.vaultVpc;
        tags = subnetTags // {Source = "NixOps"; Name = "${name}";};

      };
    in
      { 
        privateRouteTable = route;
        publicRouteTable = route;
        natRouteTable = route;
       };

  resources.vpcRouteTableAssociations = 
    let
      publicSubnets = ["public-a" "public-b" "public-c"];
      privateSubnets = [ "private-a" "private-b" "private-c" ];
      natSubnet = ["nat-subnet"];
      association = {subnet, route-table}:
        { resources, name, ... }:
        {
          inherit region accessKeyId;
          subnetId = resources.vpcSubnets."${subnet}";
          routeTableId = resources.vpcRouteTables."${route-table}";
          tags = subnetTags // {Source = "NixOps"; Name = "${name}";};
        };
    in
      (builtins.listToAttrs (map (s: nameValuePair "igw-association-${s}" (association {subnet=s; route-table="publicRouteTable";}) ) (publicSubnets))) // 
      (builtins.listToAttrs (map (s: nameValuePair "nat-association-${s}" (association {subnet=s; route-table="privateRouteTable";}) ) privateSubnets)) //
      (builtins.listToAttrs (map (s: nameValuePair "custom-association-${s}" (association {subnet=s; route-table="natRouteTable";}) ) (natSubnet)));

  resources.vpcRoutes =
    let
       natRoute = {route-table, destinationBlock}:
         { resources, name, ... }:
         {
           inherit region accessKeyId;
           routeTableId = resources.vpcRouteTables."${route-table}";
           destinationCidrBlock = destinationBlock;
           natGatewayId = resources.vpcNatGateways.nat;
           tags = subnetTags // {Source = "NixOps"; Name = "${name}";};

         };
       igwRoute = {route-table}: 
         { resources, name, ... }:
         {
           inherit region accessKeyId;
           routeTableId = resources.vpcRouteTables."${route-table}";
           destinationCidrBlock = "0.0.0.0/0";
           gatewayId = resources.vpcInternetGateways.igw; 
           tags = subnetTags // {Source = "NixOps"; Name = "${name}";};
        };
     in
     {
       ldappublicRoute1 = natRoute { route-table = "privateRouteTable"; destinationBlock = "99.99.99.99/32";};
       ldappublicRoute2 = natRoute { route-table = "privateRouteTable"; destinationBlock = "99.99.99.98/32";};
       ldapPrivateRoute1 = natRoute { route-table = "publicRouteTable"; destinationBlock = "99.99.99.99/32";};
       ldapPrivateRoute2 = natRoute { route-table = "publicRouteTable"; destinationBlock = "99.99.99.98/32";};
       publicIgwRoute = igwRoute { route-table = "publicRouteTable";};
       natIgwRoute = igwRoute { route-table = "natRouteTable";};
       privateNatRoute = natRoute { route-table = "privateRouteTable"; destinationBlock = "0.0.0.0/0";};

     };
  resources.vpcEndpoints.vpcEndpoint =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.vaultVpc;
      policy = builtins.toJSON
        {
          Statement = [
            {
              Action= "*";
              Effect= "Allow";
              Resource= "*";
              Principal= "*";
            }
          ];
        };
      # make this better maybe
      routeTableIds  = [ resources.vpcRouteTables.privateRouteTable resources.vpcRouteTables.publicRouteTable ];
      serviceName = "com.amazonaws.${region}.s3";
      tags = {Source = "NixOps"; Name = "${name}";};
    };
}