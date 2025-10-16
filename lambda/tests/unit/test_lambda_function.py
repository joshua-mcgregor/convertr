import base64
import os
import io

from PIL import Image
from unittest import mock

from src.lambda_function import handler


class DummyContext:
    aws_request_id = "12345"

@mock.patch("src.lambda_function.s3")
def test_handler_success(mock_s3):
    test_image = Image.new("RGB", (10, 10), color="red")
    image_bytes = io.BytesIO()
    test_image.save(image_bytes, format="JPEG")
    image_bytes.seek(0)

    encoded_image = base64.b64encode(image_bytes.getvalue()).decode("utf-8")
    event = {"body": encoded_image}
    os.environ["BUCKET_NAME"] = "test-bucket"

    response = handler(event, DummyContext())

    assert response["statusCode"] == 200
    assert "upload_12345.jpg" in response["body"]
    mock_s3.put_object.assert_called_once_with(
        Bucket="test-bucket",
        Key="upload_12345.jpg",
        Body=image_bytes.getvalue()
    )

def test_handler_no_body():
    event = {}
    os.environ["BUCKET_NAME"] = "test-bucket"
    response = handler(event, DummyContext())
    assert response["statusCode"] == 400
    assert response["body"] == "No data sent"

def test_handler_invalid_base64():
    event = {"body": "not_base64!"}
    os.environ["BUCKET_NAME"] = "test-bucket"
    response = handler(event, DummyContext())
    assert response["statusCode"] == 400
    assert response["body"] == "Invalid base64"

def test_handler_invalid_file_type():

    invalid_file_type = base64.b64encode(b"string").decode("utf-8")
    event = {"body": invalid_file_type}
    os.environ["BUCKET_NAME"] = "test-bucket"

    response = handler(event, DummyContext())

    assert response["statusCode"] == 400
    assert response["body"] == "Invalid image file"
