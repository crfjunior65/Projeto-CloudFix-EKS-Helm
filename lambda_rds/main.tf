# Data source para buscar a instância RDS
data "aws_db_instance" "rds_instance" {

  db_instance_identifier = var.db_instance_identifier

}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "rds_scheduler_role" {
  name = "RDSSchedulerLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "rds_scheduler_policy" {
  name        = "RDSSchedulerLambdaPolicy"
  description = "Policy for RDS Scheduler Lambda to start/stop RDS instances and write logs."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "rds:DescribeDBInstances"
        ],
        Effect   = "Allow",
        Resource = data.aws_db_instance.rds_instance.db_instance_arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_scheduler_attach" {
  role       = aws_iam_role.rds_scheduler_role.name
  policy_arn = aws_iam_policy.rds_scheduler_policy.arn
}

resource "aws_lambda_function" "rds_scheduler_lambda" {
  function_name = "RDSScheduler"
  handler       = "lambda_function.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.rds_scheduler_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DB_INSTANCE_IDENTIFIER = data.aws_db_instance.rds_instance.db_instance_identifier
    }
  }

  timeout = 60
}

# Regra para parar a instância (19:00 horário de Brasília = 22:00 UTC)
resource "aws_cloudwatch_event_rule" "stop_rds_rule" {
  name        = "StopRDSEveryNight"
  description = "Stops the RDS instance every night at 19:00 (Brasília time)"

  schedule_expression = "cron(0 21 * * MON-FRI *)" # 21:00 UTC = 18:00 Brasília

}

# Regra para iniciar a instância (07:00 horário de Brasília = 10:00 UTC)
resource "aws_cloudwatch_event_rule" "start_rds_rule" {
  name        = "StartRDSEveryMorning"
  description = "Starts the RDS instance every morning at 07:00 (Brasília time)"

  schedule_expression = "cron(0 12 * * MON-FRI *)" # 12:00 UTC = 09:00 Brasília

}

# Alvo para a regra de parada
resource "aws_cloudwatch_event_target" "stop_rds_target" {
  rule  = aws_cloudwatch_event_rule.stop_rds_rule.name
  arn   = aws_lambda_function.rds_scheduler_lambda.arn
  input = jsonencode({ "action" : "stop" })
}

# Alvo para a regra de início
resource "aws_cloudwatch_event_target" "start_rds_target" {
  rule  = aws_cloudwatch_event_rule.start_rds_rule.name
  arn   = aws_lambda_function.rds_scheduler_lambda.arn
  input = jsonencode({ "action" : "start" })
}

# Permissão para o EventBridge invocar a Lambda (parada)
resource "aws_lambda_permission" "allow_cloudwatch_to_call_stop_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch_Stop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_scheduler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_rds_rule.arn
}

# Permissão para o EventBridge invocar a Lambda (início)
resource "aws_lambda_permission" "allow_cloudwatch_to_call_start_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch_Start"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_scheduler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_rds_rule.arn
}
