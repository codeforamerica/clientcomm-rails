# Shared Vars
variable "aws_access_key" {}
variable "aws_secret_key" {}

# App Vars
variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_app_name" {}
variable "heroku_pipeline_id" {}
variable "heroku_team" {}
variable "heroku_database_plan" {
  default = "heroku-postgresql:standard-0"
}
variable "route53_app_zone_id" {}
variable "app_domain" {}
variable "environment" {
  default = "production"
}

variable "intercom_app_id" {}
variable "mixpanel_token" {}
variable "sentry_endpoint" {}
variable "skylight_authentication" {}
variable "time_zone" {}
variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_phone_number" {}
variable "typeform_link" {}

variable "enable_papertrail" {
  default = true
}
variable "sentry_deploy_hook" {}

# Email Vars
variable "mailgun_api_key" {}
variable "mailgun_domain" {}
variable "mailgun_smtp_password" {}
variable "route53_email_zone_id" {}

variable "admin_email" {}
variable "admin_password" {}

variable "aws_route53_ttl" {
  default = "300"
}

variable "mailgun_require_dkim" {
  default = true
}

terraform {
  backend "s3" {}
}

# Modules
module "app" {
  source = "./app"

  aws_access_key  = "${var.aws_access_key}"
  aws_secret_key  = "${var.aws_secret_key}"
  route53_zone_id = "${var.route53_app_zone_id}"

  heroku_email         = "${var.heroku_email}"
  heroku_api_key       = "${var.heroku_api_key}"
  heroku_app_name      = "${var.heroku_app_name}"
  heroku_pipeline_id   = "${var.heroku_pipeline_id}"
  heroku_team          = "${var.heroku_team}"
  heroku_database_plan = "${var.heroku_database_plan}"

  admin_email        = "${var.admin_email}"
  admin_password     = "${var.admin_password}"

  enable_papertrail  = "${var.enable_papertrail}"
  sentry_deploy_hook = "${var.sentry_deploy_hook}"

  environment = "${var.environment}"

  mailgun_domain        = "${var.mailgun_domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"

  app_domain = "${var.app_domain}"

  intercom_app_id         = "${var.intercom_app_id}"
  mixpanel_token          = "${var.mixpanel_token}"
  sentry_endpoint         = "${var.sentry_endpoint}"
  skylight_authentication = "${var.skylight_authentication}"
  time_zone               = "${var.time_zone}"
  twilio_account_sid      = "${var.twilio_account_sid}"
  twilio_auth_token       = "${var.twilio_auth_token}"
  twilio_phone_number     = "${var.twilio_phone_number}"
  typeform_link           = "${var.typeform_link}"
}

module "email" {
  source = "./email"

  mailgun_api_key       = "${var.mailgun_api_key}"
  mailgun_domain        = "${var.mailgun_domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"
  aws_access_key        = "${var.aws_access_key}"
  aws_secret_key        = "${var.aws_secret_key}"
  route53_zone_id       = "${var.route53_email_zone_id}"
  aws_route53_ttl       = "${var.aws_route53_ttl}"
  mailgun_require_dkim  = "${var.mailgun_require_dkim}"
}
