variable "stg_name" {}
variable "stg_tags" {
  type = map
  default = {
    "environment" = "prod",
    "cost_center" = "I.T",
    "Admin" = "Dan"
  }
}
variable "data_rg_name" {}
