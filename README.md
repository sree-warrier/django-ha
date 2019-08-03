# djnago-ha

Deploy a dockerized Django Application to AWS in a VPC using Terraform, Docker Registry and EC2 Service.

Includes:

VPC
Internal DNS
RDS
EC2 instances
ELB to distribute requests across the EC2 instances
Security groups
uWSGI task definition


#Pre-requesties
Terraform should be installed. Get it from https://www.terraform.io/downloads.html to grab the latest version.
An AWS account http://aws.amazon.com/

#Usage

Building the infra using terraform commands

The following steps will walk you through the process:

1. Clone the repo::

      git clone https://github.com/sree-warrier/djnago-ha.git

2. This will be the file structure.

      django-ha $  ll
      drwxr-xr-x  12 sreekanth  sreekanth   408 Aug  3 15:41 .git
      -rw-r--r--   1 sreekanth  sreekanth   674 Aug  3 16:53 README.md
      -rw-r--r--@  1 sreekanth  sreekanth  1170 Aug  3 13:06 docker-compose.yml
      -rw-r--r--@  1 sreekanth  sreekanth   230 Aug  3 13:08 env_local_dev.sh
      drwxr-xr-x@  9 sreekanth  sreekanth   306 Aug  3 13:50 infra-tf
      drwxr-xr-x@  9 sreekanth  sreekanth   306 Aug  3 15:41 src

3. Following should be created before terraform file execution

    - Create a keypair
    - Use the AMI having docker and docker-compose running
    - Configure aws credentials (Make sure user should have all access to the aws services)

4. infra-tf directory conatins the terraform file for infra setup, use the following steps

      cd infra-tf
      terraform init
      terraform plan
      terraform apply

5. Login to the cluster instance using the keys.

5. Create docker-compose.yml file

    touch docker-compose.yml

        version: '3.3'
        services:
          django-ha:
              image: sreewarrier24/django-ha:0.5-alpine
              command: /bin/sh /code/docker-entrypoint.sh
              environment:
                DB_NAME: *******
                DB_USER: *******
                DB_PASS: *******
                DB_HOST: *******
                DB_PORT: *******
                ELB_NAME: *******
              ports:
                  - "8000:8000"

   Update the environment variables which are prompted during the terraform execution

6. Run docker using the docker-compose file.

      docker-compose up

7. Use the ELB CNAME record to access via browser.