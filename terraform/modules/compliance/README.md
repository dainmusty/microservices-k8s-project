# Explanation of Changes:
Fixed Invalid Policy ARN:

Updated the config-role policy ARN to arn:aws:iam::aws:policy/AWSConfigRole.
Added S3 Bucket Policy:

Added an aws_s3_bucket_policy resource to allow AWS Config to write to the S3 bucket.
Added Dependencies:

Ensured aws_config_configuration_recorder_status depends on aws_config_configuration_recorder.
Ensured aws_config_config_rule depends on aws_config_configuration_recorder_status.
Removed Invalid File Reference:

Removed invalid references to undeclared resources and files.

#optional 1
config rules configuration
resource "aws_config_config_rule" "rules" {
  for_each = { for rule in var.config_rules : rule.name => rule }

  name = each.value.name

  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  # Optional input_parameters (just use a conditional)
  input_parameters = try(each.value.input_parameters, null)

  # Optional scope for compliance resource types
  dynamic "scope" {
    for_each = try(each.value.compliance_resource_types, []) != [] ? [1] : []
    content {
      compliance_resource_types = each.value.compliance_resource_types
    }
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}

#option 2
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
}

resource "aws_config_delivery_channel" "channel" {
  name           = "main-delivery-channel"
  s3_bucket_name = var.bucket_name
  
}

resource "aws_config_config_rule" "rules" {
  for_each = { for rule in var.config_rules : rule.name => rule }

  name             = each.value.name
  source {
    owner             = "AWS"
    source_identifier = each.value.source_identifier
  }

  input_parameters = try(each.value.input_parameters, null) // Use input_parameters if provided

  scope {
    compliance_resource_types = try(each.value.compliance_resource_types, null)
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}



Valid values for delivery_frequency:
One_Hour

Three_Hours

Six_Hours

Twelve_Hours

TwentyFour_Hours