import base64
import json
import requests
import io
import os

from PIL import Image

url = os.getenv('API_URL') + "/upload"
login_token = os.getenv('LOGIN_TOKEN')

def test_e2e_success_with_valid_user_and_image():
    test_image = Image.new("RGB", (10, 10), color="red")
    image_bytes = io.BytesIO()
    test_image.save(image_bytes, format="JPEG")
    image_bytes.seek(0)

    encoded_image = base64.b64encode(image_bytes.getvalue()).decode("utf-8")

    headers = {
        "Authorization": f"Bearer {login_token}",
        "Content-Type": "application/json"
    }

    response = requests.post(url, json=encoded_image, headers=headers)

    assert response.status_code == 200

def test_e2e_fail_with_invalid_user():
    test_image = Image.new("RGB", (10, 10), color="red")
    image_bytes = io.BytesIO()
    test_image.save(image_bytes, format="JPEG")
    image_bytes.seek(0)

    encoded_image = base64.b64encode(image_bytes.getvalue()).decode("utf-8")

    headers = {
        "Authorization": f"Bearer test-token",
        "Content-Type": "application/json"
    }

    response = requests.post(url, json=encoded_image, headers=headers)

    assert response.status_code == 401
