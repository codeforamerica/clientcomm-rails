# using terraform to create production ClientComm Environments

This assumes that you have an *existing* heroku team and pipeline, as well as
a staging app from which to promote the initial deploy.

NOTE: All command line examples assume ZSH as the default shell. If you are using
bash substitute `=(command)` with `<(command)`

## Creating a backend

For each production instance of ClientComm you must provide a backend that points
to an s3 terraform backend provider. We use a backend file in lastpass:
```
bucket     = "[YOUR TERRAFORM STATE BUCKET]"
region     = "[REGION]"
access_key = "[ACCESS KEY]"
secret_key = "[SECRET KEY]"
```

On the command line, use the `terraform init` command to point to this backend
and specify the key, or environment name, of the deployment you're managing
```bash
terraform init -backend-config =(lpass show --notes terraform-backend) -backend-config 'key=[DEPLOYMENT NAME]'
```

## Prepping a Twilio account

After buying a phone number navigate to: https://www.twilio.com/console/runtime/triggers/alert/create
We create the following triggers but by no means are they the only ones worth creating

* Trigger on ANY alert, at value 1 (First alert of the day)
* Trigger on ANY alert, at value 10 (Alert after 10 issues in a single day)

## Managing a ClientComm deployment

Once you have set your backend you are ready to manage a production deployment.
We use a var-file in lastpass to contain secrets and specific configuration
for each deployment:
```
mailgun_api_key = ""
mailgun_domain = ""
mailgun_smtp_password = ""
aws_access_key = ""
aws_secret_key = ""

route53_email_zone_id = ""
route53_app_zone_id = ""

heroku_email = ""
heroku_api_key = ""
heroku_app_name = ""
app_domain = ""
heroku_pipeline_id = ""
heroku_team = ""
heroku_database_plan = "heroku-postgresql:standard-0"

intercom_app_id = ""
mixpanel_token = ""
sentry_endpoint = ""
skylight_authentication = ""
time_zone = ""
twilio_account_sid = ""
twilio_auth_token = ""
twilio_phone_number = ""
typeform_link = ""
```

While most of these variables may be self explanatory there are a few details
that need further explanation:
* the route53 app zone ID variable should point to a zone file that hosts the
main domain you wish to use for your deployments. This will be used to create
the [deployment].[main_domain].tld CNAME record in your route53 zone that points
at heroku
* the route53 email zone ID variable behaves largely the same as app zone ID
but is used to create the proper mx and TXT (for SPIF and DKIM) records for sending
email with mailgun, as HSTS prevents us from sharing a domain across the app and mailgun.
* currently due to the behavior of the heroku provider you must provide an email
associated with a heroku account that has access to the pipeline you want to use.

Once you have created and saved the var file in lastpass you are ready to deploy:
```bash
terraform plan -var-file =(lpass show --notes [YOUR VAR FILE])
```

If you believe the plan accurately reflects the changes or additions you wish
to make you are ready to run apply:
```bash
terraform apply -var-file =(lpass show --notes [YOUR VAR FILE])
```
