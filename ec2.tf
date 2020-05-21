resource "aws_instance" "drupal" {
  # Image
  ami                    = "${lookup(var.aws_amis, var.region)}"
  # Size
  instance_type          = "${var.instance_type}"
  # Apply SSH key
  key_name               = "${var.key_name}"
  # Firewall rules
  security_groups        = ["${aws_security_group.drupal_ec2.id}"]
  # Put this one in availability zone a
  subnet_id              = "${aws_subnet.drupal_a.id}"
  # Tag
  tags {
    Name = "Drupal"
  }
  provisioner "file" {
    source      = "scripts/drupal.sh"
    destination = "/tmp/drupal.sh"
    connection {
        user = "admin"
    }
  }
  provisioner "file" {
    source      = "configs/apache.conf"
    destination = "/tmp/apache.conf"
    connection {
        user = "admin"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y --force-yes install apache2 libapache2-mod-php5 php5-mysql php5-gd php5-curl php5-cli",
      "chmod +x /tmp/drupal.sh",
      "sudo bash /tmp/drupal.sh ${aws_db_instance.drupal.username}:drupalpass@${aws_db_instance.drupal.address}:${aws_db_instance.drupal.port}/${aws_db_instance.drupal.name}"
    ]
    connection {
        user = "admin"
    }
  }
}
