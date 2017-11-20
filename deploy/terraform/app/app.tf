variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "route53_zone_id" {}

variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_app_name" {}
variable "heroku_pipeline_id" {}
variable "heroku_team" {}
variable "heroku_database_plan" {}

variable "environment" {}

variable "mailgun_domain" {}
variable "mailgun_smtp_password" {}

variable "app_domain" {}
variable "intercom_app_id" {}
variable "mixpanel_token" {}
variable "sentry_endpoint" {}
variable "skylight_authentication" {}
variable "time_zone" {}
variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_phone_number" {}
variable "typeform_link" {}

variable "enable_papertrail" {}
variable "sentry_deploy_hook" {}

variable "admin_email" {}
variable "admin_password" {}

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
    DEPLOYMENT = "${var.heroku_app_name}"
    DEPLOY_BASE_URL = "https://${var.app_domain}"
    INTERCOM_APP_ID = "${var.intercom_app_id}"
    LANG = "en_US.UTF-8"
    MAILGUN_DOMAIN = "${var.mailgun_domain}"
    MAILGUN_PASSWORD = "${var.mailgun_smtp_password}"
    MIXPANEL_TOKEN = "${var.mixpanel_token}"
    RACK_ENV = "${var.environment}"
    RAILS_ENV = "${var.environment}"
    RAILS_LOG_TO_STDOUT = "enabled"
    RAILS_SERVE_STATIC_FILES = "true"
    SENTRY_ENDPOINT = "${var.sentry_endpoint}"
    SKYLIGHT_AUTHENTICATION = "${var.skylight_authentication}"
    TIME_ZONE = "${var.time_zone}"
    TWILIO_ACCOUNT_SID = "${var.twilio_account_sid}"
    TWILIO_AUTH_TOKEN = "${var.twilio_auth_token}"
    AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.paperclip.secret}"
    AWS_ACCESS_KEY_ID = "${aws_iam_access_key.paperclip.id}"
    AWS_ATTACHMENTS_BUCKET = "${aws_s3_bucket.paperclip.bucket}"
    TWILIO_PHONE_NUMBER = "${var.twilio_phone_number}"
    TYPEFORM_LINK = "${var.typeform_link}"
    UNCLAIMED_EMAIL = "${var.unclaimed_email}"
  }
}

resource "aws_s3_bucket" "paperclip" {
  bucket = "${var.heroku_app_name}-attachments"
  region = "us-east-1"
  versioning {
    enabled = true
  }
}

resource "aws_iam_user" "paperclip" {
  name = "${var.heroku_app_name}-paperclip"
}

resource "aws_iam_access_key" "paperclip" {
  user = "${aws_iam_user.paperclip.name}"
}

resource "aws_iam_user_policy" "paperclip" {
  name = "paperclip_uploads"
  user = "${aws_iam_user.paperclip.name}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutObjectAcl"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.paperclip.arn}/*"
            ]
        }
    ]
}
POLICY
}

resource "heroku_addon" "database" {
  lifecycle = {
    prevent_destroy = true
  }

  app  = "${heroku_app.clientcomm.name}"
  plan = "${var.heroku_database_plan}"
}

resource "heroku_addon" "sentry_deploy_hook" {
  app = "${heroku_app.clientcomm.name}"
  plan = "deployhooks:http"

  config = {
    url = "${var.sentry_deploy_hook}"
  }
}

resource "heroku_addon" "logging" {
  count = "${var.enable_papertrail ? 1 : 0}"
  app  = "${heroku_app.clientcomm.name}"
  plan = "papertrail:choklad"
}

resource "aws_s3_bucket" "logging_bucket" {
  count = "${var.enable_papertrail ? 1 : 0}"
  bucket = "${var.heroku_app_name}-logs"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "allow_papertrail" {
  count = "${var.enable_papertrail ? 1 : 0}"
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

resource "heroku_pipeline_coupling" "coupling" {
  app      = "${heroku_app.clientcomm.name}"
  pipeline = "${var.heroku_pipeline_id}"
  stage    = "${var.environment}"
}

resource "null_resource" "provision_app" {
  depends_on = ["heroku_pipeline_coupling.coupling", "heroku_addon.database"]

  provisioner "local-exec" {
    command = "heroku pipelines:promote --app clientcomm-try --to ${heroku_app.clientcomm.name}"
  }

  provisioner "local-exec" {
    command = "heroku ps:scale web=1 worker=1 --app ${heroku_app.clientcomm.name}"
  }
}

resource "null_resource" "schedule_backups" {
  depends_on = ["heroku_addon.database"]

  provisioner "local-exec" {
    command = "heroku pg:backups:schedule DATABASE_URL --at '02:00 America/Los_Angeles' --app ${heroku_app.clientcomm.name}"
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

resource "null_resource" "unclaimed_account" {
  depends_on = ["null_resource.provision_app"]

  provisioner "local-exec" {
    command = "heroku run -a ${heroku_app.clientcomm.name} -- rake 'setup:admin_account[${var.admin_email}, ${var.admin_password}]'"
  }
}
