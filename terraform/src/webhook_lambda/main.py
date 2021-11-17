import json
import os
import requests

token = os.getenv('TOKEN')
bot_name = os.getenv('BOT_NAME')

base_url = 'https://webexapis.com/v1'

headers = {
    "Accept":  "application/json",
    "Content-type": "application/json",
    "Authorization": f"Bearer {token}"
}

def get_quote():
    quote = requests.get('https://api.kanye.rest')
    return quote.json()['quote']

def get_message(message_id):
    message_url = f'{base_url}/messages/{message_id}'
    message_text = requests.get(message_url, headers=headers).json()['text']
    return message_text

def send_message(room_id, quote):
    body = {
        "roomId": room_id,
        "text": quote
    }
    message_url = f"{base_url}/messages"
    post_message = requests.post(message_url, headers=headers, data=json.dumps(body))
    return post_message.status_code


def lambda_handler(event, context):

    webhook_data = json.loads(event['body'])
    print(f'received event {webhook_data}')
    room_id = webhook_data['data']['roomId']
    message_id = webhook_data['data']['id']
    message = get_message(message_id)
    print(f'received message {message}')
    if message == f"{bot_name} quote":
        send_status = send_message(room_id, get_quote())
        print(f'send status: {send_status}')

    return {'statusCode': 200}
