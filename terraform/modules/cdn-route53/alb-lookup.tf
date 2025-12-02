# Your Ingress should set a stable name via:
# alb.ingress.kubernetes.io/load-balancer-name: <your-alb-name>
data "aws_lb" "eks_ingress_alb" {
  name = var.alb_name
}

output "alb_dns_name" { value = data.aws_lb.eks_ingress_alb.dns_name }
output "alb_zone_id"  { value = data.aws_lb.eks_ingress_alb.zone_id  }
