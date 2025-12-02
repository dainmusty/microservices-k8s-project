 output "hosted_zone_name"                   { 
    value = aws_route53_zone.dev_hosted_zone.zone_id 
    description = "The ID of the hosted zone"
    }

