output aws-availability-zones-eu {
  value = data.aws_availability_zones.available_eu
}

output aws-availability-zones-us {
  value = data.aws_availability_zones.available_us
}
