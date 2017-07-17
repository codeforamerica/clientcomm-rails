# How to Provision an Environment for ClientComm

## Provisioning mailgun and Route53

Note: this assumes your DNS setup is using AWS Route53. If not, you cannot use
programmatic provisioning of Mailgun DNS settings

### How To

1. Create a lastpass note and replace the following variables
   ```hcl
   mailgun_api_key       = "REPLACE_ME"
   mailgun_domain        = "REPLACE_ME"
   mailgun_smtp_password = "REPLACE_ME"
   aws_access_key        = "REPLACE_ME"
   aws_secret_key        = "REPLACE_ME"
   route53_zone_id       = "REPLACE_ME"
   ```
1. (OPTIONAL) set the `mailgun_require_dkim` variable to `false` if you have
   already verified the root domain you are trying to set with mailgun
1. run the apply script
   ```bash
   apply.sh <(lpass show --notes "THE_NAME_OF_YOUR_NOTE")
   ```
1. verify in Mailgun and Route53 that your resources created correctly

