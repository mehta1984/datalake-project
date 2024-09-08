# Create DynamoDB Table
resource "aws_dynamodb_table" "my_table" {
  name         = "my-dynamodb-table" # Table name
  billing_mode = "PAY_PER_REQUEST"   # Use on-demand billing mode

  # Define the partition (hash) key and sort (range) key if needed
  hash_key  = "id"         # Partition key (Primary key)
  range_key = "created_at" # Sort key (Optional)

  # Define attributes used for keys
  attribute {
    name = "id"
    type = "S" # S for String, N for Number, B for Binary
  }

  attribute {
    name = "created_at"
    type = "N" # N for Number (e.g., timestamp)
  }

  # Optional Global Secondary Index (GSI)
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status" # Index on status
    projection_type = "ALL"

    write_capacity = 5
    read_capacity  = 5
  }

  attribute {
    name = "status"
    type = "S" # Index attribute
  }

  # Optional Provisioned Throughput (used only if billing_mode is not PAY_PER_REQUEST)
  # provisioned_throughput {
  #   read_capacity  = 1
  #   write_capacity = 1
  # }

  tags = {
    Name        = "MyDynamoDBTable"
    Environment = "Production"
  }
}

