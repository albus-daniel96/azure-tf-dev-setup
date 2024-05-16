variable "target_rg_name" {
  type = string
  default = "TWD"
}
variable "target_vnet_name" {
  type = string
  default = "west_europe_network" 
}
variable "target_subnet" {}
variable "vm_name" {}
variable "vm_size" {
    type = list
}
variable "vm_sku" {
    type = list
}
variable "computer_name" {}
variable "public_ip_needed" {}
variable "disk_count" {}
variable "disk_size_gb" {}
variable "log_work_space" {}
variable "log_ws_id" {}
variable "log_ws_key" {}
