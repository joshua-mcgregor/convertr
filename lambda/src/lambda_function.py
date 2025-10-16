from PIL import Image

import base64
import boto3
import os
import io
import json
import logging

logger = logging.getLogger(__name__)

s3 = boto3.client('s3')

def handler(event, context):
    bucket = os.environ['BUCKET_NAME']

    body = event.get('body')

    if not body:
        return {"statusCode": 400, "body": "No data sent"}
    
    try:
        file_data = base64.b64decode(body)
    except Exception:
        return {"statusCode": 400, "body": "Invalid base64"}
    
    if not is_valid_image(file_data):
        return {"statusCode": 400, "body": "Invalid image file"}

    file_key = f"upload_{context.aws_request_id}.jpg"
    
    logger.info("Writing file with key \"%s\" to S3 bucket \"%s\".", file_key, bucket)
    s3.put_object(Bucket=bucket, Key=file_key, Body=file_data)
    
    return {"statusCode": 200, "body": f"File uploaded as {file_key}"}

def is_valid_image(data: bytes) -> bool:
    try:
        with Image.open(io.BytesIO(data)) as img:
            img.verify()
        return True
    except Exception:
        return False
