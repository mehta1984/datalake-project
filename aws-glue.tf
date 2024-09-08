resource "aws_iam_role" "glue_role" {
  name = "glue_execution_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "glue_policy" {
  name = "glue_policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          aws_s3_bucket.my_bucket.arn,
          "${aws_s3_bucket.my_bucket.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem"
        ],
        "Resource" : aws_dynamodb_table.my_table.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_glue_job" "s3_to_dynamodb" {
  name     = "s3_to_dynamodb_glue_job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://bhavin-mehta-datalake-project/my-folder/scripts/glue_s3_to_dynamodb.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://bhavin-mehta-datalake-project/my-folder/temp/"
  }

  max_retries       = 1
  glue_version      = "2.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}





# lamda function 

data "archive_file" "python_lambda_package_glue" {
  type        = "zip"
  source_file = "${path.module}/code/glue_trigger.py"
  output_path = "glue_trigger_function_payload.zip"
}

resource "aws_lambda_function" "glue_job_trigger_lambda" {
  function_name = "trigger_glue_job_lambda"
  role          = aws_iam_role.lambda_role.arn

  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  filename         = "glue_trigger_function_payload.zip" # Zip file containing your Lambda code
  //source_code_hash = filebase64sha256("glue_trigger_function_payload.zip")
  source_code_hash = data.archive_file.python_lambda_package_glue.output_base64sha256
}

# resource "aws_lambda_permission" "allow_cloudwatch_trigger" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.glue_job_trigger_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.s3_object_created_rule.arn
# }

# Allow S3 bucket to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invocation_gluelambda" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_job_trigger_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_event_glue" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.glue_job_trigger_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "my-folder/processed/" # Optional: Only trigger for objects in this prefix
  }

  depends_on = [
    aws_s3_bucket.my_bucket,
    aws_lambda_function.glue_job_trigger_lambda
  ]
}