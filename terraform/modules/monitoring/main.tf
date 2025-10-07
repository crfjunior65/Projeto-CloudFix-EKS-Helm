# Dashboards com ALB dinâmico
resource "aws_cloudwatch_dashboard" "main" {
  for_each = var.dashboard_definitions

  dashboard_name = each.key
  dashboard_body = each.value
}

# ========================================
# ALARMES
# ========================================

# Alarmes EKS - Pod Memory High
resource "aws_cloudwatch_metric_alarm" "cloudfix_app_memory_high" {
  alarm_name          = "${var.cluster_name}-default-cloudfix-app-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "pod_memory_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Pod memory utilization high"
  alarm_actions       = var.sns_topic_arn_for_alarms != "" ? [var.sns_topic_arn_for_alarms] : []

  dimensions = {
    ClusterName = var.cluster_name
    Namespace   = "default"
    Service     = "cloudfix-app"
  }
}

# Alarmes EKS - Pod Count Low
resource "aws_cloudwatch_metric_alarm" "cloudfix_app_pod_count_low" {
  alarm_name          = "${var.cluster_name}-default-cloudfix-app-pod-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "service_number_of_running_pods"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "Pod count too low"
  alarm_actions       = var.sns_topic_arn_for_alarms != "" ? [var.sns_topic_arn_for_alarms] : []

  dimensions = {
    ClusterName = var.cluster_name
    Namespace   = "default"
    Service     = "cloudfix-app"
  }
}

# Alarmes EKS - CPU High
resource "aws_cloudwatch_metric_alarm" "cluster_cpu_high" {
  alarm_name          = "${var.cluster_name}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Cluster CPU utilization high"
  alarm_actions       = var.sns_topic_arn_for_alarms != "" ? [var.sns_topic_arn_for_alarms] : []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

# Alarmes EKS - Memory High
resource "aws_cloudwatch_metric_alarm" "cluster_memory_high" {
  alarm_name          = "${var.cluster_name}-memory-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Cluster memory utilization high"
  alarm_actions       = var.sns_topic_arn_for_alarms != "" ? [var.sns_topic_arn_for_alarms] : []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

# Alarmes RDS - CPU High
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.db_instance_identifier}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "RDS CPU utilization high"
  alarm_actions       = var.sns_topic_arn_for_alarms != "" ? [var.sns_topic_arn_for_alarms] : []

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }
}
