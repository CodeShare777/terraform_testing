import json

def lambda_handler(event, context):
    print("Hello! Lambda just ran.")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Terraform Lambda!')
    }
