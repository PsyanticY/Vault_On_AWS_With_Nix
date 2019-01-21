{ region    ? "us-east-1"
, account   ? "account"
, accountId ? "xxxxxxxxxxx"
}:

{
resources.s3Buckets.Vault-bucket = 
  { resources, ... }:
  { 
    inherit region;
    accessKeyId = account;
    name = "Vault-bucket";
    policy = builtins.toJSON ''
      {
        Id = "denyDeletion";
        Statement = [
           {
              Sid = "denyDeletion";
              Action = [ "s3:DeleteBucket" ];
              Effect = "Deny";
              Resource = "arn:aws:s3:::pdx-vault-assets";
              Principal = { AWS = [ "*" ]; };
          };
          {
              Sid = "denyObjectDeletion";
              Action = [ "s3:DeleteObject" ];
              Effect = "Deny";
              Resource = "arn:aws:s3:::pdx-vault-assets/*";
              Principal = { AWS = [ "*" ]; };
          };
        ];
      };
    '';
  };

resources.iamRoles.consul-server-role =
  { resources, ... }:
  {
    accessKeyId = account;
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
          };
      }
    '';
    };
}
