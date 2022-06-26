import json
import os

def lambda_handler(event, context):
    endpoint_to_probe = os.environ["endpoint_to_probe"]
    print(f"Checking endpoint: {endpoint_to_probe}")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Terraform Lambda!')
    }
