import json

import requests
import os

token = os.getenv("TF_VAR_webhook_token")
webhook_url = os.getenv('WEBHOOK_URL')
base_url = 'https://webexapis.com/v1'

headers = {
    "Accept":  "application/json",
    "Content-type": "application/json",
    "Authorization": f"Bearer {token}"
}

webhook = {
    "name": "kanyebot",
    "targetUrl": webhook_url,
    "resource": "messages",
    "event": "created",
}

webhook_create = requests.post(f"{base_url}/webhooks", headers=headers, json=webhook)

print(f'Create Status {webhook_create.status_code}')

print('Create response...')

print(json.dumps(webhook_create.json(), indent=2))