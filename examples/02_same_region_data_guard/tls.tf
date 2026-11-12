# Generate a lab SSH key when the caller does not supply public keys.
resource "tls_private_key" "public_private_key_pair" {
  count     = length(var.ssh_public_keys) == 0 ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  ssh_public_keys = length(var.ssh_public_keys) > 0 ? var.ssh_public_keys : [tls_private_key.public_private_key_pair[0].public_key_openssh]
}

output "ssh_private_key_pem" {
  description = "Generated lab SSH private key; null when caller supplies public keys. Stored in state."
  value       = length(var.ssh_public_keys) == 0 ? tls_private_key.public_private_key_pair[0].private_key_pem : null
  sensitive   = true
}
