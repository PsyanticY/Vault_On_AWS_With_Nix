{ region      ? "us-east-1"
, accessKeyId ? "None"
, accountId   ? "xxxxxxxxxxx"
, ...
}:

{
resources.s3Buckets.Vault-bucket = 
  { 
    inherit region accessKeyId;
    name = "Vault-bucket";
    policy = builtins.toJSON ''
      {
        Id = "denyDeletion";
        Statement = [
           {
              Sid = "denyDeletion";
              Action = [ "s3:DeleteBucket" ];
              Effect = "Deny";
              Resource = "arn:aws:s3:::vaultbackup";
              Principal = { AWS = [ "*" ]; };
          };
          {
              Sid = "denyObjectDeletion";
              Action = [ "s3:DeleteObject" ];
              Effect = "Deny";
              Resource = "arn:aws:s3:::vaultbackup/*";
              Principal = { AWS = [ "*" ]; };
          };
        ];
      };
    '';
  };

resources.iamRoles = 
  let 
    vaultAndConsulPolicy = builtins.toJSON ''
      {
        Action = [ "ec2:DescribeInstances" ];
        Resource = "*";
        Effect = "Allow";
      };
    '';
  in
    {
      consul-server-role =
        { resources, ... }:
        {
          inherit accessKeyId;
          policy = builtins.toJSON ''
          {
          Statement =  
            {
              Action = [
                "s3:Get*"
                "s3:Put*"
                "s3:List*"
              ];
              Effect = "Allow";
              Resource = [
                "arn:aws:s3:::${resources.s3Buckets.Vault-bucket.name}"
	        "arn:aws:s3:::${resources.s3Buckets.Vault-bucket.name}/*"
              ];
            } ++ vaultAndConsulPolicy;
          };
          '';
        };

      vault-role =
        { resources, ... }:
        {
          inherit accessKeyId;
          policy = builtins.toJSON ''
            {
              Statement = ${vaultAndConsulPolicy};
            };
          '';
        };
    };

resources.ec2KeyPairs.kp =
  { 
    inherit region; accessKeyId = account; 
  };
}
