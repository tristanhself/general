resource "aws_customer_gateway" "VPN-CGW-1" {
  bgp_asn    = "65001"
  ip_address = "1.2.3.4"
  type       = "ipsec.1"

  tags = {
    Name = "VPN-CGW-1"
  }
}

resource "aws_vpn_connection" "TGW-VPN-1" {
  customer_gateway_id      = aws_customer_gateway.VPN-CGW-1.id
  transit_gateway_id       = aws_ec2_transit_gateway.TGW.id
  type                     = "ipsec.1"
  tunnel_inside_ip_version = "ipv4"

  local_ipv4_network_cidr  = "10.0.0.0/8"
  remote_ipv4_network_cidr = "192.168.1.0/24"

  tunnel1_ike_versions = ["ikev2"]
  tunnel2_ike_versions = ["ikev2"]

  tunnel1_dpd_timeout_action = "clear"
  tunnel2_dpd_timeout_action = "clear"

  tunnel1_dpd_timeout_seconds = 30
  tunnel2_dpd_timeout_seconds = 30

  tunnel1_preshared_key = "<passkey 1>"
  tunnel2_preshared_key = "<passkey 2>"

  tunnel1_inside_cidr = "169.254.254.100/30"
  tunnel2_inside_cidr = "169.254.254.104/30"

  #phase1
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]

  tunnel1_phase1_integrity_algorithms = ["SHA2-256", "SHA2-512"]
  tunnel2_phase1_integrity_algorithms = ["SHA2-256", "SHA2-512"]

  tunnel1_phase1_dh_group_numbers = [14, 21]
  tunnel2_phase1_dh_group_numbers = [14, 21]

  tunnel1_phase1_lifetime_seconds = 14400
  tunnel2_phase1_lifetime_seconds = 14400

  #phase2
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_encryption_algorithms = ["AES256"]

  tunnel1_phase2_integrity_algorithms = ["SHA2-256", "SHA2-512"]
  tunnel2_phase2_integrity_algorithms = ["SHA2-256", "SHA2-512"]

  tunnel1_phase2_dh_group_numbers = [14, 21]
  tunnel2_phase2_dh_group_numbers = [14, 21]

  tunnel1_phase2_lifetime_seconds = 3600
  tunnel2_phase2_lifetime_seconds = 3600

  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled = true
      log_group_arn = aws_cloudwatch_log_group.VPN_Tunnel1_Log_Group.arn
      log_output_format = "text"
    }
  }

  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled = true
      log_group_arn = aws_cloudwatch_log_group.VPN_Tunnel2_Log_Group.arn
      log_output_format = "text"
    }
  }

  tags = {
    Name = "TGW-VPN-1"
  }
}

// Output ------------------------------------------------------------------------------------------------------------------------

output "TGW-VPN-1_Details" {
  value = aws_vpn_connection.TGW-VPN-1.vgw_telemetry
}