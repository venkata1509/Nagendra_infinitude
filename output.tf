# outputs.tf

output "vpc_id" {
  value = "vpc-09cca262899d5286d"
}

output "ec2_instance_public_ip" {
  value = "16.171.173.229"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.my_api_deployment.invoke_url
}
