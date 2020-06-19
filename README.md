# AWS with Terraform and Ansible
Wordpress deployed on AWS to learn Terraform and Ansible

>A domain is required.

## How to setup:
- Install python.
- Install terraform.
```
curl "https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip" -o "terraform-v0.12.26.zip"
unzip terraform-v0.12.26.zip
sudo mv terraform /usr/local/bin/
```
- Create an IAM user with AdministratorAccess.
- Install AWS cli and configure your profile.
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws configure --profile <Profile Name>
```
- Install ansible.
```
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```
- Generate an ssh-key and give it to the ssh-agent.
```
ssh-keygen -t rsa -b 4096

eval `ssh-agent`
ssh-add /path/to/the/private/key
ssh-add -l
```
- Create a Route 53 delegation set. (Note down the delegation set id & the name servers)
```
aws route53 create-reusable-delegation-set --caller-reference 1234 --profile <Profile Name>
```
```
# Example output:

{
    "Location": "https://route53.amazonaws.com/2013-04-01/delegationset/ABCD1234EFGH5678",
    "DelegationSet": {
        "Id": "/delegationset/ABCD1234EFGH5678",
        "CallerReference": "1234",
        "NameServers": [
            "ns-123.awsdns-45.com",
            "ns-678.awsdns-90.net",
            "ns-2814.awsdns-39.co.uk",
            "ns-1246.awsdns-75.org"
        ]
    }
}
```
- Put the name servers in the settings of your Domain Name provider.

- Now, refer to [variables.tf](../master/variables.tf) and create **terraform.tfvars** to provide values to the variables (Some defaults have been set):
```
# Example terraform.tfvars file:

aws_region     = "us-east-1"
aws_profile    = "batman"
vpc_cidr_block = "192.168.0.0/16"

subnet_cidr_block = {
    wp_public1_subnet  = "192.168.10.0/24"
    wp_public2_subnet  = "192.168.20.0/24"
    wp_private1_subnet = "192.168.30.0/24"
    wp_private2_subnet = "192.168.40.0/24"
    wp_rds1_subnet     = "192.168.50.0/24"
    wp_rds2_subnet     = "192.168.60.0/24"
    wp_rds3_subnet     = "192.168.70.0/24"
}
```
Now run these commands:  
- To initialize the directory.
```
terraform init
```  
- To create an execution plan.
```
terraform plan  
```  
- To execute the plan and create the infrastructure.
```
terraform apply 
``` 
Now, go to your domain and run the famous 5-minute WordPress installation.

Then push the wordpress files from the Dev/Bastion instance to the S3 bucket and the instances in the Auto Scaling group will sync those files up periodically.

## AWS Resources created:

### IAM Service:
- IAM Role for EC2 instances to access S3

### VPC Service:
- VPC
- Internet Gateway
- Elastic IP
- NAT Gateway
- Route Tables - Public & Private (Main)
- Subnets - Public, Private & RDS
- Security Groups - Load Balancer, Dev/Bastion, Private EC2 instances & RDS
- VPC Endpoint for S3

### S3 Service:
- S3 bucket

### RDS Service:
- RDS Subnet Group
- RDS Instance

### EC2 Service:
- Key Pair
- Dev/Bastion Instance
- Application Load Balancer & Target Group
- AMI from the Dev/Bastion Instance
- Launch Configuration
- Auto Scaling Group

### Route 53 Service:
- Public Hosted Zone - Load Balancer & Dev/Bastion Instance
- Private Hosted Zone - Database Instance


## Future Improvements:
- CloudFront
- ElastiCache

## Ansible:
- [aws_hosts:](../master/aws_hosts)  

This file will be created from the `terraform apply` command.  
It holds information like the public ip address of the Dev/Bastion instance, the S3 bucket name, the domain name and the php version to use.  
All of this information is used by the ansible playbook (**wordpress.yml**).

- [wordpress.yml:](../master/wordpress.yml)  

This ansible playbook will use the **aws_hosts** file and configure the Dev/Bastion instance.  
Tasks performed:
1. Install AWS cli
2. Install & configure Nginx
3. Install & configure php-fpm
4. Download & extract WordPress
5. Restart & Enable nginx and php-fpm services

## Other files:
- [userdata:](../master/userdata)  

This file will be created from the `terraform apply` command.  
It is the userdata script used by the **Lauch Configuration**.  
It will get the updated WordPress files from the S3 bucket and also setup a cron job for future changes.  
It will also update the nginx - server_name directive.

- [blog.example.com.conf:](../master/blog.example.com.conf)  

Nginx virtual host config file.

## Possible issues:
- Ansible is not able connect to the Dev/Bastion instance:  

Edit the **/etc/ansible/ansible.cfg** file and disable SSH key host checking.
```
# uncomment this to disable SSH key host checking
# host_key_checking = False
```
Then run this command and see if you can ping:
```
ansible --inventory aws_hosts --user ubuntu --module-name ping dev
```
- Terraform aws provider bug:

Running the `terraform apply` command may result in provider produced inconsistent final plan.  
Executing the `terraform apply` command again should fix the issue.
