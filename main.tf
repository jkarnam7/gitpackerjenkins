#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.vpc_name}"
	Owner = "KJ"
	#environment = "${var.env}"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
	tags = {
        Name = "${var.IGW_name}"
    }
}

resource "aws_subnet" "subnets" {
    count = "${length(var.cidrs)}"
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${element(var.cidrs, count.index)}"
    availability_zone = "${element(var.azs, count.index)}"
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.vpc_name}-Subnet-${count.index+1}"
    }
}

# resource "aws_subnet" "subnet2-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet2_cidr}"
#     availability_zone = "us-east-1b"

#     tags = {
#         Name = "${var.public_subnet2_name}"
#     }
# }

# resource "aws_subnet" "subnet3-public" {
#     vpc_id = "${aws_vpc.default.id}"
#     cidr_block = "${var.public_subnet3_cidr}"
#     availability_zone = "us-east-1c"

#     tags = {
#         Name = "${var.public_subnet3_name}"
#     }
	
# }


resource "aws_route_table" "terraform-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "${var.Main_Routing_Table}"
    }
}

resource "aws_route_table_association" "terraform-public" {
    count = "${length(var.cidrs)}"
    subnet_id = "${element(aws_subnet.subnets.*.id, count.index)}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
}

# data "aws_ami" "my_ami" {
#      most_recent      = true
#      #name_regex       = "^mavrick"
#      owners           = ["721834156908"]
# }


resource "aws_instance" "web-1" {
    #ami = var.imagename
    ami = "ami-04d29b6f966df153"
    #ami = "${data.aws_ami.my_ami.id}"
    count = "${var.env == "prod" ? 1 : 1}"
    #availability_zone = "${element(aws_subnet.subnets.*.id, count.index)}"
    instance_type = "t2.micro"
    key_name = "CommonKey"
    subnet_id = "${element(aws_subnet.subnets.*.id, count.index)}"
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true	
    tags = {
        Name = "${var.vpc_name}-Subnet-${count.index+1}"
        Env = "Prod"
         Owner = "KJ"
	# CostCenter = "ABCD"
    }
}

##output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}" 
#}
#!/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
#packer validate --var-file creds.json packer.json
#packer build --var-file creds.json packer.json
#packer.exe build --var-file creds.json -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve
#https://discuss.devopscube.com/t/how-to-get-the-ami-id-after-a-packer-build/36
