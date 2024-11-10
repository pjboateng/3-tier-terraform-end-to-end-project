# CREATING A SIMPLE ROUTING POLICY
resource "aws_route53_record" "dns_record" {
  zone_id = var.zone_id  # You must get this from the AWS console in Route 53
  name    = var.dns_name # Name of your registered domain in route 53
  type    = "A"
  
  alias {
    name           = var.alb_dns_name
    zone_id        = var.alb_zone_id  # The zone id for your application load balancer
    evaluate_target_health = true
  }
}