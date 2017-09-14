variable "mailgun_api_key" {}
variable "mailgun_domain" {}
variable "mailgun_smtp_password" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "route53_zone_id" {}

variable "aws_route53_ttl" {
  default = "300"
}

variable "mailgun_require_dkim" {
  default = true
}

provider "mailgun" {
  api_key = "${var.mailgun_api_key}"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

resource "mailgun_domain" "default" {
  name          = "${var.mailgun_domain}"
  spam_action   = "disabled"
  smtp_password = "${var.mailgun_smtp_password}"
}

resource "aws_route53_record" "mailgun_sending_record_0" {
  zone_id         = "${var.route53_zone_id}"
  name    = "${mailgun_domain.default.sending_records.0.name}."
  ttl     = "${var.aws_route53_ttl}"
  type    = "${mailgun_domain.default.sending_records.0.record_type}"
  records = ["${mailgun_domain.default.sending_records.0.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_1" {
  zone_id         = "${var.route53_zone_id}"
  name    = "${mailgun_domain.default.sending_records.1.name}."
  ttl     = "${var.aws_route53_ttl}"
  type    = "${mailgun_domain.default.sending_records.1.record_type}"
  records = ["${mailgun_domain.default.sending_records.1.value}"]
}

resource "aws_route53_record" "mailgun_sending_record_2" {
  count = "${var.mailgun_require_dkim ? 1 : 0}"
  zone_id         = "${var.route53_zone_id}"
  name    = "${mailgun_domain.default.sending_records.2.name}."
  ttl     = "${var.aws_route53_ttl}"
  type    = "${mailgun_domain.default.sending_records.2.record_type}"
  records = ["${mailgun_domain.default.sending_records.2.value}"]
}

resource "aws_route53_record" "mailgun_receiving_records_mx" {
  zone_id = "${var.route53_zone_id}"
  name = ""
  ttl     = "${var.aws_route53_ttl}"
  type = "MX"
  records = [
    "${mailgun_domain.default.receiving_records.0.priority} ${mailgun_domain.default.receiving_records.0.value}",
    "${mailgun_domain.default.receiving_records.1.priority} ${mailgun_domain.default.receiving_records.1.value}"
  ]
}
