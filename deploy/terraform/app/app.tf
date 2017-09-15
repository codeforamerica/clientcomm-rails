variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_app_name" {}
variable "heroku_pipeline_id" {}
variable "heroku_team" {}

variable "route53_zone_id" {}

variable "app_domain" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}

# Configure the Heroku provider
provider "heroku" {
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

resource "heroku_app" "clientcomm" {
  name   = "${var.heroku_app_name}"
  region = "us"
  organization = {
    name = "${var.heroku_team}"
  }
}

resource "heroku_addon" "database" {
  app  = "${heroku_app.clientcomm.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_pipeline_coupling" "production" {
  app      = "${heroku_app.clientcomm.name}"
  pipeline = "${var.heroku_pipeline_id}"
  stage    = "production"
}

resource "null_resource" "provision_app" {
  provisioner "local-exec" {
    command = "heroku pipelines:promote --app clientcomm-try --to ${heroku_app.clientcomm.name}"
  }

  provisioner "local-exec" {
    command = "heroku ps:scale web=1 worker=1 --app ${heroku_app.clientcomm.name}"
  }
}

resource "heroku_domain" "clientcomm" {
  app      = "${heroku_app.clientcomm.name}"
  hostname = "${var.app_domain}"
}

resource "aws_route53_record" "clientcomm" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.app_domain}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${heroku_domain.clientcomm.cname}"]
}

resource "null_resource" "ssl" {
  depends_on = ["null_resource.provision_app"]

  provisioner "local-exec" {
    command = "heroku ps:resize hobby --app ${heroku_app.clientcomm.name}"
  }

  provisioner "local-exec" {
    command = "heroku certs:auto:enable --app ${heroku_app.clientcomm.name}"
  }
}
