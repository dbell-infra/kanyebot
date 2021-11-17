// Source code payload, S3 bucket, and S3 upload

data "archive_file" "webhook_src_zip" {
  type = "zip"

  source_dir  = "${path.module}/src/webhook_lambda"
  output_path = "${path.module}/bin/${var.webhook_function}.zip"
}

resource "aws_s3_bucket" "webhook_bucket" {
  bucket = "${var.bucket_prefix}-${var.webhook_function}-src"

  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "webhook_src" {
  bucket = aws_s3_bucket.webhook_bucket.id

  key    = "${var.webhook_function}.zip"
  source = data.archive_file.webhook_src_zip.output_path

  etag = filemd5(data.archive_file.webhook_src_zip.output_path)
}

// Lambda IAM
resource "aws_iam_role" "github_webhook_exec" {
  name = "${var.webhook_function}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

}
resource "aws_iam_role_policy_attachment" "github_webhook_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.github_webhook_exec.name
}

// Lambda function

resource "aws_lambda_function" "github_webhook" {
  function_name = var.webhook_function

  s3_bucket = aws_s3_bucket.webhook_bucket.id
  s3_key    = aws_s3_bucket_object.webhook_src.key

  runtime = "python3.8"
  handler = "main.lambda_handler"

  source_code_hash = data.archive_file.webhook_src_zip.output_base64sha256

  role = aws_iam_role.github_webhook_exec.arn
   environment {
    variables = {
      TOKEN = var.webhook_token
      BOT_NAME = var.chatbot_name
    }
  }
}

resource "aws_cloudwatch_log_group" "github_webhook_logs" {
  name = "/aws/lambda/${aws_lambda_function.github_webhook.function_name}"

  retention_in_days = 30
}

//API Gateway Integration
resource "aws_api_gateway_rest_api" "webhook_api" {
  name = "${var.webhook_function}-api"
}

resource "aws_api_gateway_resource" "webhook_resource" {
  parent_id   = aws_api_gateway_rest_api.webhook_api.root_resource_id
  path_part   = var.webhook_function
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id
}
resource "aws_api_gateway_method" "webhook_method" {
  authorization = "NONE"
  http_method   = "ANY"
  resource_id   = aws_api_gateway_resource.webhook_resource.id
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.webhook_api.id
  resource_id             = aws_api_gateway_resource.webhook_resource.id
  http_method             = aws_api_gateway_method.webhook_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.github_webhook.invoke_arn
}

resource "aws_lambda_permission" "github_webhook_api_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_webhook.arn
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.webhook_api.id}/*/*/${var.webhook_function}"
}

resource "aws_api_gateway_deployment" "webhook_api" {
  rest_api_id = aws_api_gateway_rest_api.webhook_api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.webhook_api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_api_gateway_method.webhook_method]
}

resource "aws_api_gateway_stage" "webhook" {
  deployment_id = aws_api_gateway_deployment.webhook_api.id
  rest_api_id   = aws_api_gateway_rest_api.webhook_api.id
  stage_name    = "webhook"
}
