output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.game_store_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the created EC2 instance"
  value       = aws_eip.game_store_eip.public_ip
}

output "application_urls" {
  description = "URLs to access the application"
  value = {
    frontend = "http://${aws_eip.game_store_eip.public_ip}:5003"
    backend  = "http://${aws_eip.game_store_eip.public_ip}:5274"
  }
}
