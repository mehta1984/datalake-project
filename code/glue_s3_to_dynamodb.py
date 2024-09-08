import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
import boto3

# Initialize Glue job
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Read data from S3
s3_input_path = "s3://bhavin-mehta-datalake-project/my-folder/processed/"
input_dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [s3_input_path]},
    format="csv"  # Change format to csv, parquet, etc., as needed
)

# Convert DynamicFrame to a DataFrame
input_df = input_dynamic_frame.toDF()

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('my-dynamodb-table')

# Write data to DynamoDB
for row in input_df.collect():
    table.put_item(Item=row.asDict())

# Commit Glue job
job.commit()
