output "server_ip" {
  value       = aws_instance.node_app.public_ip
  description = "The public IP of the Node.js server"
}
