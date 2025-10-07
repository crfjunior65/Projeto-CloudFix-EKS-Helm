locals {
  # Container Insights - Cluster/Node Level
  network_rx_expression = jsonencode("SEARCH(\"{ContainerInsights,ClusterName} MetricName=\\\"node_network_rx_bytes\\\"\", \"Sum\", 300)")
  network_tx_expression = jsonencode("SEARCH(\"{ContainerInsights,ClusterName} MetricName=\\\"node_network_tx_bytes\\\"\", \"Sum\", 300)")

  # Container Insights - Pod/Namespace Level
  cpu_namespace_expression    = jsonencode("SEARCH(\"{ContainerInsights,ClusterName,Namespace} MetricName=\\\"pod_cpu_utilization\\\" ClusterName=\\\"${module.eks.k8s_name}\\\"\", \"Average\", 300)")
  memory_namespace_expression = jsonencode("SEARCH(\"{ContainerInsights,ClusterName,Namespace} MetricName=\\\"pod_memory_utilization\\\" ClusterName=\\\"${module.eks.k8s_name}\\\"\", \"Average\", 300)")

  # ALB Metrics (using SEARCH expressions)
  alb_request_count_expression        = jsonencode("SEARCH(\"{AWS/ApplicationELB,LoadBalancer} MetricName=\\\"RequestCount\\\"\", \"Sum\", 60)")
  alb_target_response_time_expression = jsonencode("SEARCH(\"{AWS/ApplicationELB,LoadBalancer} MetricName=\\\"TargetResponseTime\\\"\", \"Average\", 60)")
  alb_http_2xx_expression             = jsonencode("SEARCH(\"{AWS/ApplicationELB,LoadBalancer} MetricName=\\\"HTTPCode_Target_2XX_Count\\\"\", \"Sum\", 60)")
  alb_http_4xx_expression             = jsonencode("SEARCH(\"{AWS/ApplicationELB,LoadBalancer} MetricName=\\\"HTTPCode_Target_4XX_Count\\\"\", \"Sum\", 60)")
  alb_http_5xx_expression             = jsonencode("SEARCH(\"{AWS/ApplicationELB,LoadBalancer} MetricName=\\\"HTTPCode_Target_5XX_Count\\\"\", \"Sum\", 60)")
}


/*
resource "aws_cloudwatch_dashboard" "cloudfix_dashboard_teste" {
  dashboard_name = format("%s-dashboard-consolidado-teste", var.prefix)
  dashboard_body = templatefile("${path.module}/cloudwatch/dashboard-consolidado.json.tftpl", {
    region                 = var.region
    cluster_name           = module.eks.k8s_name
    db_instance_identifier = module.rds.db_instance_id
    environment            = var.environment
    # Pass new expressions to the template
    network_rx_expr               = local.network_rx_expression
    network_tx_expr               = local.network_tx_expression
    cpu_namespace_expr            = local.cpu_namespace_expression
    memory_namespace_expr         = local.memory_namespace_expression
    alb_request_count_expr        = local.alb_request_count_expression
    alb_target_response_time_expr = local.alb_target_response_time_expression
    alb_http_2xx_expr             = local.alb_http_2xx_expression
    alb_http_4xx_expr             = local.alb_http_4xx_expression
    alb_http_5xx_expr             = local.alb_http_5xx_expression
  })
}
*/

# Dashboard completamente funcional com todas as métricas funcionando
resource "aws_cloudwatch_dashboard" "cloudfix_dashboard_funcional_completo" {
  dashboard_name = format("%s-dashboard-funcional-completo", var.prefix)
  dashboard_body = templatefile("${path.module}/cloudwatch/dashboard-funcional-completo.json.tftpl", {
    region                 = var.region
    cluster_name           = module.eks.k8s_name
    db_instance_identifier = module.rds.db_instance_id
    environment            = var.environment
    LABEL                  = var.LABEL
  })
  depends_on = [time_sleep.wait_for_cloudwatch]
}
