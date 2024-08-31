
# Introduction

This is terraform project to create datalake using AWS. Service used for this projects are as below.
AWS S3, Lambda function, IAM Roles. 

- Create S3 Bucket and create folder structrue i.e. dirty, processed and clean
- Create IAM roles and permission to give lamda function to read the S3 object and move the S3 object
- Create S3 notificate event for Lambda function 
- One S3 Crate Object Event, Labmda function will read the file, process the file and move file to processed folder. 



## Terraform Commands 
terraform init
terraform fmt
terraform validate
terraform apply
terraform show
terraform destroy