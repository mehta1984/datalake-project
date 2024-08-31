# main.tf

# Specify the provider
provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "bhavin-mehta-datalake-project" # Replace with your desired bucket name


  tags = {
    Name        = "MyBucket"
    Environment = "Dev"
  }
}

# Configure Server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "awsRule" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning 
# resource "aws_s3_bucket_versioning" "versioning" {
#   bucket = aws_s3_bucket.my_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }

# }

# enable ACL to be private 
resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# enable ACL to be private 
resource "aws_s3_bucket_acl" "aclrule" {
  depends_on = [aws_s3_bucket_ownership_controls.ownership_controls]

  bucket = aws_s3_bucket.my_bucket.id
  acl    = "private"
}


variable "s3_folders" {
  type        = list(string)
  description = "The list of S3 folders to create"
  default     = ["dirty", "clean", "processed"]
}




# Create a folder (prefix) inside the S3 bucket by uploading an empty object
resource "aws_s3_object" "my_folder" {
  count  = length(var.s3_folders)
  bucket = aws_s3_bucket.my_bucket.bucket
  // key    = "my-folder/"  # The trailing slash denotes a folder
  key = "my-folder/${var.s3_folders[count.index]}/"
  acl = "private"
}


# Create an IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach a policy to the IAM role to allow logging
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create Lambda function (Replace with your function specifics)
# resource "aws_lambda_function" "my_lambda_function" {
#   function_name = "my_lambda_function"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "index.handler"
#   runtime       = "python3.8"

#   # You should replace this with your own Lambda deployment package
#   filename      = "lambda_function_payload.zip"  # Replace with your Lambda deployment package
#   source_code_hash = filebase64sha256("lambda_function_payload.zip")
# }


# IAM Policy for S3 read/write access for Lambda
resource "aws_iam_policy" "lambda_s3_read_write_policy" {
  name        = "LambdaS3ReadWritePolicy"
  description = "Policy to allow Lambda to read/write to a specific S3 folder"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.my_bucket.arn
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = "my-folder/*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CopyObject"
        ]
        Resource = [
          "${aws_s3_bucket.my_bucket.arn}/my-folder/*"
        ]
      }
    ]
  })
}

# Attach the S3 read/write policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_read_write_policy.arn
}


# lamda function 

data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/code/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

# Lambda function to read CSV 

# Create Lambda function
resource "aws_lambda_function" "csv_reader_lambda" {
  function_name = "csv_reader_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  # You should replace this with the path to your deployment package zip
  filename = "lambda_function_payload.zip" # This should be a zip file with lambda_function.py inside it
  //source_code_hash = filebase64sha256("lambda_function_payload.zip")
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256

  
}


# Allow S3 bucket to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_reader_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

# Create S3 bucket notification to trigger Lambda on object creation
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_reader_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "my-folder/dirty/" # Optional: Only trigger for objects in this prefix
  }

  depends_on = [
    aws_s3_bucket.my_bucket,
    aws_lambda_function.csv_reader_lambda
                 
                ]
}

