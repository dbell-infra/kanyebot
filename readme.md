# Deploy a Kanye-Quote Chatbot for Webex Teams with Terraform and AWS

This repo contains code to provision a webhook endpoint using AWS Lambda, AWS API Gateway and Python 
to implement a WebEx Teams chatbot that echos Kanye quotes into a chat room.

To use this repo: 

Provision a chatbot via developer.webex.com and save the access token. 

Clone this repo

set the following envrionment variables 

`TF_VAR_aws_account_id=XXXXXXXXXXX`

`TF_VAR_bucket_prefix=mybucket-naming-convention`

`TF_VAR_webhook_token=XXXXXXXXXXXXX`

Override any default values found in variables.tf if desired/necessary

Run terraform init and terraform apply to deploy the services. 

From the outputs post-apply, extract the invoke_url 

set the following environment variable 

`WEBHOOK_URL=https://XXXXXXXX.execute-api.us-east-2.amazonaws.com/webhook/kanyebot-webhook"`

run the setup_webhook.py script 

`python setup_webhook.py`

Add the chatbot to a room and call the chatbot

`@<chat_bot_name> quote`


![chatbot](https://i.imgur.com/gXeejJ6.png)
