# Vault_On_AWS_With_Nix
Fully NixOps managed HashiCorp Vault on AWS

##
The architecutre will be a bit different then the one AWS did provide, as it provided many resource that are uneeded.

resources to be created with NixOps:
- VPC:
  * 3 private subnets
  * 3 public subnets
  * A NAT Subnet.
  * Internet gateway
  * 4 Elastic IPs
- EC2 Instances:
  * 2 Vault servers
  * 2 Consul servers (will ommit the 3 Consul Client cause i don't know why they are used for)
  * a Bastion host.
- Security groups:
  * 1 For Bastion host: external workd access.
  * 1 for internal access between all the Instances.
  * 1 - 5 attached to vault server to serve external world requests.
- S3 bucket to store vault backups.
- IAM roles

...

Access will be managed via an OpenLdap/FreeIPA/AD Server. Or just manually.

###Things to improve:

- work on how to make consul server really in a private subnet (nixops needs to support a jump hosts)
- Work on datadog monitoring.
