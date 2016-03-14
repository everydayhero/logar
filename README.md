# Logar
Provisions a self-managed Elasticsearch cluster in AWS for storing logs using [Terraform](https://www.terraform.io).

This will create an Elasticsearch cluster that automatically curates old indices and funnel logs set to a AWS Kinesis stream or AWS CloudWatch Logs.

## Prerequisites

* [Terraform](https://www.terraform.io) v0.6.12
* [Node](https://www.nodejs.org) v0.10.36+

## Usage

```
terraform get -update=true # Fetches latest dependencies
terraform plan -out terraform.tfplan -var access_key=... -var secret_key=... -var region=...
terraform apply terraform.tfplan
```

## Options

`keyname`  
Required. The key to use for provisioning EC2 instances. Without this you will NOT be able to SSH onto the cluster.

`subnet_ids`  
Required. A comma separated list of AWS subnet IDs. The more subnets specified, the more spread out the cluster will be.

`vpc_id`  
Required. The ID of the VPC for the cluster to be provisioned in. This must be the VPC same as the VPC the subnets belong to.

`instance_type`  
Defaults to m3.medium. The EC2 instance type to use for the cluster.

`volume_size`  
Defaults to 100Gb. The storage capacity per node.

`cluster_size`  
Defaults to 3. The number of nodes in the cluster.

`index_retention`  
Defaults to 14 days. How many days to keep each Elasticsearch index.

`excluded_indices`  
Defaults to .kibana. Which Elasticsearch indices to not remove.

## Todo

* Fix rebuilding functions
* Auto-scaling when low of storage
