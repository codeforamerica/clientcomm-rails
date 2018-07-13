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
variable "intercom_secret_key" {}
variable "mixpanel_token" {}
variable "sentry_endpoint" {}
variable "skylight_authentication" {}
variable "time_zone" {}
variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_phone_number" {}

variable "enable_papertrail" {}
variable "papertrail_plan" {}

variable "admin_email" {}
variable "admin_password" {}
variable "devise_secret_key_base" {}
variable "report_day" {}
variable "unclaimed_email" {}
variable "unclaimed_password" {}
variable "department_name" {}

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
    AWS_ACCESS_KEY_ID = "${aws_iam_access_key.paperclip.id}"
    AWS_ATTACHMENTS_BUCKET = "${aws_s3_bucket.paperclip.bucket}"
    AWS_KMS_KEY_ID = "${aws_kms_key.bucket_key.arn}"
    AWS_SECRET_ACCESS_KEY = "${aws_iam_access_key.paperclip.secret}"
    DEPLOYMENT = "${var.heroku_app_name}"
    DEPLOY_BASE_URL = "https://${var.app_domain}"
    INTERCOM_APP_ID = "${var.intercom_app_id}"
    INTERCOM_SECRET_KEY = "${var.intercom_secret_key}"
    LANG = "en_US.UTF-8"
    MAILGUN_DOMAIN = "${var.mailgun_domain}"
    MAILGUN_PASSWORD = "${var.mailgun_smtp_password}"
    MIXPANEL_TOKEN = "${var.mixpanel_token}"
    RACK_ENV = "${var.environment}"
    RAILS_ENV = "${var.environment}"
    RAILS_LOG_TO_STDOUT = "enabled"
    RAILS_SERVE_STATIC_FILES = "true"
    REPORT_DAY = "${var.report_day}"
    SECRET_KEY_BASE = "${var.devise_secret_key_base}"
    SENTRY_ENDPOINT = "${var.sentry_endpoint}"
    SKYLIGHT_AUTHENTICATION = "${var.skylight_authentication}"
    TIME_ZONE = "${var.time_zone}"
    TWILIO_ACCOUNT_SID = "${var.twilio_account_sid}"
    TWILIO_AUTH_TOKEN = "${var.twilio_auth_token}"
    TWILIO_PHONE_NUMBER = "${var.twilio_phone_number}"
  }
}

resource "aws_kms_key" "bucket_key" {
  description = "This key is used to encrypt bucket objects"
}

resource "aws_s3_bucket" "paperclip" {
  bucket = "${var.heroku_app_name}-attachments"
  region = "us-east-1"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.bucket_key.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
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
        },
        {
            "Action": [
              "kms:CreateGrant",
              "kms:ListGrants",
              "kms:RevokeGrant",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey",
              "kms:Encrypt",
              "kms:Decrypt"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_kms_key.bucket_key.arn}"
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

resource "heroku_addon" "logging" {
  count = "${var.enable_papertrail ? 1 : 0}"
  app  = "${heroku_app.clientcomm.name}"
  plan = "${var.papertrail_plan}"
}

resource "heroku_addon" "scheduler" {
  app  = "${heroku_app.clientcomm.name}"
  plan = "scheduler:standard"
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

resource "null_resource" "dyno_metadata" {
  depends_on = ["null_resource.provision_app"]

  provisioner "local-exec" {
    command = "heroku labs:enable runtime-dyno-metadata --app ${heroku_app.clientcomm.name}"
  }
}

resource "null_resource" "provision_accounts" {
  depends_on = ["null_resource.provision_app"]

  provisioner "local-exec" {
    command = "heroku run -a ${heroku_app.clientcomm.name} -- rake 'setup:admin_account[${var.admin_email}, ${var.admin_password}]'"
  }

  provisioner "local-exec" {
    command = "heroku run -a ${heroku_app.clientcomm.name} -- rake 'setup:unclaimed_account[${var.unclaimed_email}, ${var.unclaimed_password}]'"
  }

  provisioner "local-exec" {
    command = "heroku run -a ${heroku_app.clientcomm.name} -- rake 'setup:install_department[${var.department_name}]'"
  }
}

resource "null_resource" "open_scheduler" {
  provisioner "local-exec" {
    command = "heroku addons:open ${heroku_addon.scheduler.id}"
  }
}
