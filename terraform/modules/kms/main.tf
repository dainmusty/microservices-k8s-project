resource "aws_kms_key" "kms_key_dev" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
}

resource "aws_kms_alias" "kms_alias_dev" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.kms_key_dev.id
}
