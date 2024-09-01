
# Introduction

This is terraform project to create datalake using AWS. Service used for this projects are as below.
AWS S3, Lambda function, IAM Roles. 

Below are the high level steps it performs. 

- Create S3 Bucket and create folder structrue i.e. dirty, processed and clean.
- Create a Lamdba function to process the file and move to processed folder. 
- Create IAM roles and permission to give Lamdba function to list, read, write and delete the S3 objects.
- Create S3 notificate event for Lambda function. This will invoke Lambda function on S3 createObject. 
- On S3 Create Object Event, Labmda function will be invoked, it will read the file, process the file and move file to processed folder. 



## Terraform Commands 
terraform init
terraform fmt
terraform validate
terraform apply
terraform show
terraform destroy