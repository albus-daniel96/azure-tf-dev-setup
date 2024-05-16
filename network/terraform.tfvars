nsg_name = "west_europe_subnet_nsg"
network_name = "west_europe_network"
address_space = ["10.0.0.0/16"]
dns_servers = ["10.0.0.4", "10.0.0.5"]
subnet_name_address = [
    {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
    },
    {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
    }
]
network_tags = {
    "Project"="ShipRock",
    "Admin"="James",
    "Cost-Center"="Internal-IT"
}
