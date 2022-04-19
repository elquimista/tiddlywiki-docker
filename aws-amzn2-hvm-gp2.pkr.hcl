#
# MIT License
# Copyright (c) 2022-2022 Nicola Worthington <nicolaw@tfb.net>
#
# https://gitlab.com/nicolaw/tiddlywiki
# https://nicolaw.uk
# https://nicolaw.uk/#TiddlyWiki
#

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type        = string
  description = "Name of the region, such as us-east-1, in which to launch the EC2 instance to create the AMI."
  default     = "eu-west-2"
}

variable "public_ami" {
  type        = bool
  description = "Make the AMI publically accessible by setting ami_groups to 'all'."
  default     = true
}

variable "ami_regions" {
  type        = list(string)
  description = "List of regions to copy the AMI to. AMI copyiy will generally take many minutes."
  default     = ["eu-west-2"]
}

source "amazon-ebs" "default-public" {
  ssh_username            = "ec2-user"
  ami_virtualization_type = "hvm"

  region        = var.region
  ami_groups    = var.public_ami ? ["all"] : null
  encrypt_boot  = var.public_ami ? false : true
  ami_regions   = var.ami_regions

  # https://github.com/hashicorp/packer-plugin-amazon/issues/18
  associate_public_ip_address = true

  vpc_filter {
    filters = {
      "isDefault": "true"
    }
  }

  subnet_filter {
    most_free = true
    random    = true
    filters = {
      "subnet-id": "*"
    }
  }
}

locals {
  architecture_instance_type_map = {
    x86_64 = "t3.micro"
    arm64  = "t4g.micro"
  }
}

build {
  name    = "tiddlywiki"

  dynamic "source" {
    for_each = local.architecture_instance_type_map
    labels   = ["amazon-ebs.default-public"]

    content {
      ami_name        = "tiddlywiki-ami-hvm-${ formatdate("YYYYMMDD", timestamp()) }-${ source.key }-gp2"
      ami_description = "TiddlyWiki Linux AMI ${ formatdate("YYYYMMDD", timestamp()) } ${ source.key } HVM gp2"
      instance_type   = source.value

      source_ami_filter {
        filters = {
          name                = "amzn2-ami-hvm-2.0.*"
          root-device-type    = "ebs"
          virtualization-type = "hvm"
          architecture        = source.key
          owner-alias         = "amazon"
        }
        most_recent = true
        owners      = ["137112412989"]
      }
    }
  }

  provisioner "file" {
    sources = [
      "tiddlywiki.service",
      "tiddlywiki.conf",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sleep 10",
      "sed -i 's/^[[:space:]]*#[[:space:]]*TW_PORT=.*/TW_PORT=80/' /tmp/tiddlywiki.conf",
      "sudo mkdir -pv /etc/tiddlywiki/ /home/ec2-user/tiddlywiki/",
      "sudo mv -v /tmp/tiddlywiki.service /etc/systemd/system/tiddlywiki.service",
      "sudo mv -v /tmp/tiddlywiki.conf /etc/tiddlywiki/tiddlywiki.conf",
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable docker.service",
      "sudo systemctl start docker.service",
      "sleep 10",
      "sudo docker volume create --name tiddlywiki --opt type=none --opt device=/home/ec2-user/tiddlywiki --opt o=bind",
      "sudo systemctl enable tiddlywiki.service",
      "sudo systemctl start tiddlywiki.service",
    ]
  }
}
