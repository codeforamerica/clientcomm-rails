# Shared Vars
variable "aws_access_key" {}
variable "aws_secret_key" {}

# App Vars
variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_app_name" {}
variable "heroku_pipeline_id" {}
variable "heroku_team" {}
variable "route53_app_zone_id" {}
variable "app_domain" {}

# Email Vars
variable "mailgun_api_key" {}
variable "mailgun_domain" {}
variable "mailgun_smtp_password" {}
variable "route53_email_zone_id" {}

variable "aws_route53_ttl" {
  default = "300"
}

variable "mailgun_require_dkim" {
  default = true
}

# Modules
module "app" {
  source = "./app"

  aws_access_key        = "${var.aws_access_key}"
  aws_secret_key        = "${var.aws_secret_key}"
  route53_zone_id       = "${var.route53_app_zone_id}"

  heroku_email          = "${var.heroku_email}"
  heroku_api_key        = "${var.heroku_api_key}"
  heroku_app_name       = "${var.heroku_app_name}"
  heroku_pipeline_id    = "${var.heroku_pipeline_id}"
  heroku_team           = "${var.heroku_team}"

  mailgun_domain        = "${var.mailgun_domain}"
  mailgun_smtp_password = "${var.mailgun_smtp_password}"

  app_domain            = "${var.app_domain}"
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
