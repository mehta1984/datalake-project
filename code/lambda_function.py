import boto3
import csv
import urllib.parse

def lambda_handler(event, context):
    # Get the S3 bucket and object key from the event
    s3 = boto3.client('s3')
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']

    # Read the CSV file from S3
    try:
        print("bucket_name:"+bucket_name)
        print("object_key:"+object_key)
        response = s3.get_object(Bucket=bucket_name, Key=object_key)
        csv_content = response['Body'].read().decode('utf-8').splitlines()
        csv_reader = csv.reader(csv_content)
        
        # Print each row in the CSV file
        for row in csv_reader:
           print(row)
           
        # Get bucket name and object key from the event
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

        # Define the destination bucket and key
        destination_bucket = source_bucket  # Same bucket
        destination_key = source_key.replace('dirty/', 'processed/', 1)

        print("destination_bucket:"+destination_bucket)
        print("destination_key:"+destination_key)

                # Copy the object to the new location
        copy_source = {'Bucket': source_bucket, 'Key': source_key}
        s3.copy_object(CopySource=copy_source, Bucket=destination_bucket, Key=destination_key)
        print(f"Copied {source_key} to {destination_key}")

        # Delete the original object
        s3.delete_object(Bucket=source_bucket, Key=source_key)
        print(f"Deleted {source_key} from {source_bucket}")
    
    except Exception as e:
        print(f"Error reading {object_key} from bucket {bucket_name}: {e}")
        print(f"Error moving file from {source_key} to {destination_key}: {e}")
        raise e