output "vm_password" {
  value = random_string.password.result
  description = "VM Password"
}
