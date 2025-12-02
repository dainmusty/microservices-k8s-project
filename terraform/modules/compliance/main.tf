resource "aws_config_configuration_recorder" "recorder" {
  name     = "main-config-recorder"
  role_arn = var.config_role_arn

  recording_group {
    all_supported                 = var.recording_gp_all_supported
    include_global_resource_types = var.recording_gp_global_resources_included
  }
}

resource "aws_config_configuration_recorder_status" "status" {
  name       = aws_config_configuration_recorder.recorder.name
  is_enabled = var.recorder_status_enabled

  depends_on = [aws_config_delivery_channel.channel]
}


resource "aws_config_delivery_channel" "channel" {
  name           = "main-delivery-channel"
  s3_bucket_name = var.config_bucket_name
  s3_key_prefix  = var.config_s3_key_prefix
}


resource "aws_config_config_rule" "rules" {
  for_each = { for rule in var.config_rules : rule.name => rule }

  name = each.value.name

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  // Optional input_parameters (just use a conditional)
  input_parameters = try(each.value.input_parameters, null)

  // Optional scope for compliance resource types
  dynamic "scope" {
    for_each = try(each.value.compliance_resource_types, []) != [] ? [1] : []
    content {
      compliance_resource_types = each.value.compliance_resource_types
    }
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}


