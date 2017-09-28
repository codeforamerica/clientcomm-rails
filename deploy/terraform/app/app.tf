variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "route53_zone_id" {}

variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_app_name" {}
variable "heroku_pipeline_id" {}
variable "heroku_team" {}

variable "mailgun_domain" {}
variable "mailgun_smtp_password" {}


variable "app_domain" {}


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

  config_vars {
    DEPLOY_BASE_URL = "https://${var.app_domain}"
    MAILGUN_DOMAIN = "${var.mailgun_domain}"
    MAILGUN_PASSWORD = "${var.mailgun_smtp_password}"
    LANG = "en_US.UTF-8"
    RACK_ENV = "production"
    RAILS_ENV = "production"
    RAILS_LOG_TO_STDOUT = "enabled"
    RAILS_SERVE_STATIC_FILES = true
    MASS_MESSAGES = true
    UNCLAIMED_EMAIL = "clientcomm+unclaimed@codeforamerica.org"
  }
}

resource "heroku_addon" "database" {
  app  = "${heroku_app.clientcomm.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_addon" "logging" {
  app  = "${heroku_app.clientcomm.name}"
  plan = "papertrail:choklad"
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = "${var.heroku_app_name}-logs"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "allow_papertrail" {
  bucket = "${aws_s3_bucket.logging_bucket.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PapertrailLogArchive",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::719734659904:root"
                ]
            },
            "Action": [
                "s3:DeleteObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.logging_bucket.arn}/papertrail/logs/*"
            ]
        }
    ]
}
POLICY
}

resource "heroku_pipeline_coupling" "production" {
  app      = "${heroku_app.clientcomm.name}"
  pipeline = "${var.heroku_pipeline_id}"
  stage    = "production"
}

resource "null_resource" "provision_app" {
  depends_on = ["heroku_pipeline_coupling.production"]

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
