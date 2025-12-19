# Monitoring and Diagnostic Settings
# CIS 5.1.4 - Ensure audit logs are enabled
# DoD STIG V-242461 - Enable comprehensive audit logging

# Diagnostic Settings for AKS Cluster
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.diagnostic_storage_account_id

  # All Kubernetes control plane log categories
  dynamic "enabled_log" {
    for_each = toset(local.diagnostic_log_categories)
    content {
      category = enabled_log.value
    }
  }

  # Metrics
  dynamic "metric" {
    for_each = toset(local.diagnostic_metric_categories)
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [
      log_analytics_destination_type
    ]
  }
}

# Action Group for Alerts (optional)
resource "azurerm_monitor_action_group" "aks" {
  count = var.create_action_group ? 1 : 0

  name                = "${var.cluster_name}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.cluster_name, 0, 12)

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = true
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.alert_webhook_receivers
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = true
    }
  }

  tags = local.default_tags
}

# Metric Alert: Node CPU Usage
resource "azurerm_monitor_metric_alert" "node_cpu_high" {
  count = var.create_metric_alerts ? 1 : 0

  name                = "${var.cluster_name}-node-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  description         = "Alert when node CPU usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_cpu_alert_threshold

    dimension {
      name     = "node"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.aks[0].id : var.existing_action_group_id
  }

  tags = local.default_tags
}

# Metric Alert: Node Memory Usage
resource "azurerm_monitor_metric_alert" "node_memory_high" {
  count = var.create_metric_alerts ? 1 : 0

  name                = "${var.cluster_name}-node-memory-high"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  description         = "Alert when node memory usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_memory_alert_threshold

    dimension {
      name     = "node"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.aks[0].id : var.existing_action_group_id
  }

  tags = local.default_tags
}

# Metric Alert: API Server Availability
resource "azurerm_monitor_metric_alert" "apiserver_availability" {
  count = var.create_metric_alerts ? 1 : 0

  name                = "${var.cluster_name}-apiserver-down"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  description         = "Alert when API server availability drops"
  severity            = 0
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "cluster_autoscaler_cluster_safe_to_autoscale"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.aks[0].id : var.existing_action_group_id
  }

  tags = local.default_tags
}

# Metric Alert: Pod Count Near Limit
resource "azurerm_monitor_metric_alert" "pod_count_high" {
  count = var.create_metric_alerts ? 1 : 0

  name                = "${var.cluster_name}-pod-count-high"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  description         = "Alert when pod count approaches max"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_phase"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.pod_count_alert_threshold
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.aks[0].id : var.existing_action_group_id
  }

  tags = local.default_tags
}

# Log Analytics Query Alert: Failed Pod Starts
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_pod_starts" {
  count = var.create_log_alerts ? 1 : 0

  name                = "${var.cluster_name}-failed-pod-starts"
  resource_group_name = var.resource_group_name
  location            = var.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes              = [var.log_analytics_workspace_id]
  severity            = 2
  enabled             = true

  criteria {
    query = <<-QUERY
      KubePodInventory
      | where ClusterName == '${var.cluster_name}'
      | where PodStatus == 'Failed'
      | summarize FailedPods = count() by Namespace, PodName
      | where FailedPods > 5
    QUERY

    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = var.create_action_group ? [azurerm_monitor_action_group.aks[0].id] : [var.existing_action_group_id]
  }

  tags = local.default_tags
}

# Container Insights (Azure Monitor for Containers)
# Additional monitoring beyond OMS agent
resource "azurerm_log_analytics_solution" "container_insights" {
  count = var.enable_container_insights ? 1 : 0

  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.log_analytics_workspace_resource_group != "" ? var.log_analytics_workspace_resource_group : var.resource_group_name
  workspace_resource_id = var.log_analytics_workspace_id
  workspace_name        = var.log_analytics_workspace_name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.default_tags
}
