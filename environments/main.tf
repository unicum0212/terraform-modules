resource "aws_instance" "env_server" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.terraform_remote_state.admin.outputs.public_subnet_1
  vpc_security_group_ids = [var.sec_group]
  user_data              = file("launch-conf.sh")
  key_name               = var.keypair

  root_block_device {
    volume_size = 12
  }

  tags = {
    Name        = "PetClinic-${var.env}"
    Environment = "${var.env}"
  }
}
