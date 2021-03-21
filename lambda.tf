locals {
  lambda_function_name = "lambda_function"
}

data "archive_file" "lambda_archive" {
  type = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "lambda_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:*:${var.develop_account_id}:secret:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "lambda_secrets" {
  policy = data.aws_iam_policy_document.lambda_secrets.json
  name = "lambda_secrets"
  path = "/"
  description = "IAM policy for SecretManager from a lambda"
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_secrets.arn
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_log_group" {
  name = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${var.develop_account_id}:log-group:${aws_cloudwatch_log_group.lambda_cloudwatch_log_group.name}:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${var.develop_account_id}:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"
  policy = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_lambda_function" "test_lambda" {
  filename = data.archive_file.lambda_archive.output_path
  function_name = local.lambda_function_name
  role = aws_iam_role.iam_for_lambda.arn
  handler = "${local.lambda_function_name}.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda_archive.output_path)
  runtime = "python3.8"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda_cloudwatch_log_group,
  ]
}

resource "aws_lambda_alias" "lambda_alias" {
  name = "latest"
  function_name = aws_lambda_function.test_lambda.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id = "allow_cloudwatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = "arn:aws:events:${data.aws_region.current.name}:${var.develop_account_id}:rule/${aws_cloudwatch_event_rule.lambda_cron.name}"
  qualifier = aws_lambda_alias.lambda_alias.name
}

resource "aws_cloudwatch_event_rule" "lambda_cron" {
  name = "run-lambda-to-check-old-iam-passwords"
  description = "Schedule trigger for run every day at midnight"
  schedule_expression = "rate(1 day)"
  role_arn = aws_iam_role.iam_for_cloudwatch.arn
}

data "aws_iam_policy_document" "cloudwatch_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "events.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_lambda" {
  policy = data.aws_iam_policy_document.cloudwatch_lambda.json
  name = "cloudwatch_lambda"
  path = "/"
  description = "IAM policy for Lambda from Cloudwatch"
}

resource "aws_iam_role" "iam_for_cloudwatch" {
  name = "iam_for_cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_lambda" {
  policy_arn = aws_iam_policy.cloudwatch_lambda.arn
  role = aws_iam_role.iam_for_cloudwatch.name
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  arn = aws_lambda_alias.lambda_alias.arn
  rule = aws_cloudwatch_event_rule.lambda_cron.id
}
