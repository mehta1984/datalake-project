import boto3

def lambda_handler(event, context):
    glue_client = boto3.client('glue')
    glue_client.start_job_run(JobName='s3_to_dynamodb_glue_job')
