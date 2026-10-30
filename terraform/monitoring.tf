resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  for_each = module.ec2

  alarm_name          = "${var.project_name}-${each.key}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Instancia ${each.key} falhou no status check (instance ou system)"
  dimensions = {
    InstanceId = each.value.instance_id
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_log_group" "app" {
  for_each          = toset(local.environments)
  name              = "/${var.project_name}/${each.key}/app"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "app_error_logs" {
  for_each = toset(local.environments)

  alarm_name          = "${var.project_name}-${each.key}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/${each.key}"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_description   = "Mais de 5 erros de aplicacao (level=error) em 5 minutos em ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  for_each       = toset(local.environments)
  name           = "${var.project_name}-${each.key}-error-filter"
  log_group_name = aws_cloudwatch_log_group.app[each.key].name
  pattern        = "\"level\":\"error\""

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${each.key}"
    value     = "1"
  }
}
