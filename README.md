README

This repository contains an example set of Terraform manifests for building a basic Drupal 8 at AWS.
What does it do?

    Provisions AWS security groups
    Provisions a VPC in us-west-1
    Provisions a VPC in eu-central-1
    Provisions VPC Peering between the above two VPC
    Provisions an RDS instance with a Drupal database
    Provisions an EC2 instance (for Drupal app)
    Installs Drupal 8 and relevant dependencies on the EC2 instance

What else can I do with Terraform?

A lot more. See the Terraform docs.
