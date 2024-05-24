data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role_backend" {
  name = "backend-lambda-role-${var.enviroment}"
  description = "lambda role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_backend" {
  role = aws_iam_role.lambda_role_backend.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "backend_lambda" {
  function_name = "backend-service-${var.enviroment}"
  filename = "${path.module}/${var.zip_file_path}"
  runtime = "java17"
  handler = "tr.edu.metu.sm703.HomeController::index"
  memory_size = "512"
  timeout = "120"
  
  source_code_hash = "${base64sha256(filebase64("${path.module}/${var.zip_file_path}"))}"
  role = aws_iam_role.lambda_role_backend.arn

  environment {
    variables = {
      PARAM1 = "VALUE"
    }
  }
}


resource "aws_cloudwatch_log_group" "backend_lambda" {
  name = "/aws/lambda/${aws_lambda_function.backend_lambda.function_name}"
  retention_in_days = 30
}


resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example-api-${var.enviroment}"  # Name of your API Gateway
  description = "Example API Gateway"  # Description for your API Gateway
}

resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "hello"  # Path for your resource
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"  # HTTP method for your method
  authorization = "NONE"  # Authorization type (in this example, it's set to NONE)
}

resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"  # HTTP method for your integration
  type                    = "AWS_PROXY"
  uri                     =  aws_lambda_function.backend_lambda.invoke_arn
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on = [aws_api_gateway_integration.example_integration]

  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.example_api.id}/*/GET${aws_api_gateway_resource.example_resource.path}"
}


resource "aws_cloudwatch_metric_alarm" "gateway_error_rate" {
  alarm_name          = "api-gateway-5xx-errors-${var.enviroment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Gateway error rate has exceeded 5%"
  treat_missing_data  = "notBreaching"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0.05
  statistic           = "Average"
  unit                = "Count"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.example_api.id
    Stage = "dev"
  }
}


