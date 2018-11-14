# Deploying ClientComm to production

ClientComm uses a number of third-party services to operate. You will need to have credentials with
all these services to run ClientComm in production.

- [Heroku](https://www.heroku.com/) for hosting the application.
- [Twilio](https://www.twilio.com/) for handling messages and phone calls.
- [Amazon Web Services](https://aws.amazon.com/) for domain management, file storage, and monitoring.
- [Mailgun](https://www.mailgun.com/) for sending notification and administrative emails.
- [LastPass](https://www.lastpass.com/) for secrets management.
- [Pingdom](https://www.pingdom.com/) for uptime monitoring.
- [Sentry](https://sentry.io/) for error tracking.
- [Skylight](https://www.skylight.io/) for performance profiling.
- [Mixpanel](https://mixpanel.com/) for analytics.
- [Intercom](https://www.intercom.com/) for customer support.

*Heroku*, *Twilio*, *AWS*, and *Mailgun* are critical services; ClientComm cannot run without them.
*LastPass*, *Pingdom*, *Sentry*, *Skylight*, *Mixpanel*, and *Intercom* are useful tools for developing,
maintaining, and supporting ClientComm, but are not necessary for it to run.

The deploy process assumes that you have an *existing* [Heroku team](https://devcenter.heroku.com/articles/heroku-teams)
and [Heroku pipeline](https://devcenter.heroku.com/articles/pipelines), as well as a
[staging app](https://devcenter.heroku.com/articles/multiple-environments#creating-and-linking-environments)
in that pipeline from which to promote the initial deploy.

NOTE: All command line examples assume *zsh* as the default shell. If you are using *bash* use
`<(command)` instead of `=(command)`.

## Install and configure Terraform

Install Terraform with [Homebrew](https://brew.sh/) like this: `brew install terraform`; or by
[downloading it from HashiCorp](https://www.terraform.io/downloads.html).

For each production instance of ClientComm you must provide a backend that points to an [s3
terraform backend provider](https://www.terraform.io/docs/backends/types/s3.html). We use a backend
file in LastPass named `terraform-backend`:
```
bucket     = "[THE NAME OF YOUR TERRAFORM STATE BUCKET]"
access_key = "[THE AWS ACCESS KEY OF AN ACCOUNT WITH READ/WRITE ACCESS TO THE BUCKET]"
secret_key = "[THE AWS SECRET KEY OF AN ACCOUNT WITH READ/WRITE ACCESS TO THE BUCKET]"
```

On the command line, use the `terraform init` command to point to this backend and specify the key,
or environment name, of the deployment you're managing. We use a deployment name that corresponds
with the subdomain of the deploy; so a `demo` deployment name would correspond with an app deployed
to `demo.clientcomm.org`:
```bash
terraform init -backend-config =(lpass show --notes terraform-backend) -backend-config 'key=[DEPLOYMENT NAME]'
```

## Prepping a Twilio account

In Twilio, create a new subaccount (if you use them to manage your deploys), then buy an SMS-capable
phone number in the appropriate area code. Configure the _A CALL COMES IN_ webhook
to point to `https://[DEPLOYMENT NAME].clientcomm.org/incoming/voice/` and the _A MESSAGE COMES IN_
webhook to point to `https://[DEPLOYMENT NAME].clientcomm.org/incoming/sms/`.

On the [Alert Triggers](https://www.twilio.com/console/runtime/triggers/alert/create) page, set up
the following triggers to send email to an alerts address (we use `clientcomm-alerts@codeforamerica.org`):

* Trigger on ANY alert, at value 1 (First alert of the day)
* Trigger on ANY alert, at value 10 (Alert after 10 issues in a single day)

This will give you early warning if Twilio's having trouble delivering messages to ClientComm.

## Set up an Alerts Topic

We use [AWS CloudWatch Alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)
to monitor our job queue and alert us if there's activity (or lack of activity) that requires human
attention. You will need to [set up an SNS topic](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/US_SetupSNS.html)
to send events to. Create a SNS topic called `cc-alerts` if it doesn't already exist, and add your
alerts email to it as a subscriber. If you name it something other than `cc-alerts`, you must update
[the corresponding line in the terraform file](https://github.com/codeforamerica/clientcomm-rails/blob/develop/deploy/terraform/app/app.tf#L179).

## Managing a ClientComm deployment

Create a var file in LastPass called (for example) `clientcomm-personal-terraform-secrets` with the
AWS access and secret keys of an account that has permission to create and destroy resources (Route
53 DNS records, s3 buckets, CloudWatch alarms). We use IAM credentials unique to each deployer:

```
aws_access_key = "[DEPLOYER AWS ACCESS KEY]"
aws_secret_key = "[DEPLOYER AWS SECRET ACCESS KEY]"
```

Now you're ready to manage a production deployment. We use a var file in lastpass to contain secrets
and specific configuration for each deploy:
```
mailgun_api_key = ""
mailgun_domain = ""
mailgun_smtp_password = ""
mailgun_require_dkim = "false"

route53_app_zone_id = ""
route53_email_zone_id = ""

app_domain = ""
heroku_api_key = ""
heroku_app_name = ""
heroku_email = ""
heroku_pipeline_id = ""
heroku_team = ""

papertrail_plan = "papertrail:choklad"

unclaimed_email = ""
unclaimed_password = ""

admin_email = ""
admin_password = ""
devise_secret_key_base = ""

intercom_app_id = ""
intercom_secret_key = ""
mixpanel_token = ""
sentry_deploy_hook = ""
sentry_endpoint = ""
skylight_authentication = ""
time_zone = "Pacific Time (US & Canada)"
twilio_account_sid = ""
twilio_auth_token = ""
twilio_phone_number = ""

report_day = "1"
```

Many of these variables are self-explanatory, but there are a few details that need further explanation:
* `route53_app_zone_id`: this variable should point to a zone file that hosts the main domain you wish
to use for your deployments. This will be used to create the [deployment].[main_domain].tld CNAME
record in your route53 zone that points at Heroku
* `route53_email_zone_id`: this variable behaves largely the same as app zone ID but is used to create
the proper mx and TXT (for SPIF and DKIM) records for sending email with Mailgun, as HSTS prevents
us from sharing a domain across the app and Mailgun.
* `app_domain`: the full domain of your deploy, i.e. `demo.clientcomm.org`
* `heroku_email`: currently, due to the behavior of the [Terraform Heroku provider](https://www.terraform.io/docs/providers/heroku/index.html),
you must provide an email associated with a Heroku account that has access to the pipeline you want
to use.
* `papertrail_plan`: [Papertrail](https://elements.heroku.com/addons/papertrail) is a Heroku add-on
that manages application logs; `papertrail:choklad` is the free tier. 
* `unclaimed_email`, `unclaimed_password`: used to set up the unclaimed client ClientComm account
in the new deploy.
* `admin_email`, `admin_password`: used to set up a ClientComm account with admin permissions in
the new deploy.
* `devise_secret_key_base`: [Devise](https://github.com/plataformatec/devise) is the user account
authentication system that ClientComm uses; run `rake secret` on the command line to generate a
value for this field.
* `sentry_deploy_hook`: Used to organize Sentry alerts; [set up instructions are here](https://docs.sentry.io/workflow/integrations/heroku/).
* `report_day`: ClientComm will generate and email usage reports one day a week; use this variable
to set which day that is. Set from "0" for Sunday to "6" for Saturday.

If you're maintaining multiple deploys, the variables that will definitely need to change between
deploys are: `mailgun_domain`, `app_domain`, `heroku_app_name`, `unclaimed_email`,
`unclaimed_password`, `admin_email`, `admin_password`, `devise_secret_key_base`, `time_zone`,
`twilio_account_sid`, `twilio_auth_token`, and `twilio_phone_number`.

Once you have created and saved the var file in LastPass you are ready to deploy. First get Terraform's plan for the deploy:
```bash
terraform plan -var-file =(lpass show --notes [VAR FILE NAME IN LASTPASS]) -var-file =(lpass show --notes clientcomm-personal-terraform-secrets)
```

If you believe the plan accurately reflects the changes or additions you wish to make, run apply:
```bash
terraform apply -var-file =(lpass show --notes [VAR FILE NAME IN LASTPASS]) -var-file =(lpass show --notes clientcomm-personal-terraform-secrets)
```

There is a manual step during the deploy; the [Heroku Scheduler](https://devcenter.heroku.com/articles/scheduler) interface will
launch. Add two jobs; one for the Twilio status update rake task to run every 10 minutes:

```
rake messages:update_twilio_statuses
```

And one for the usage report rake task to run once a day:

```
rake reports:generate_and_send_reports
```

Although `generate_and_send_reports` will run daily, it'll only send emails when the day of the week
matches the value of the `report_day` variable mentioned above.

## Finishing Touches

There are a few finishing touches that must be done manually.

### Verify the domain in Mailgun

You'll need to log in to Mailgun to verify the email domain. Click on the *Domains* menu, click the
new domain that was just created, and click the *Check DNS Records Now* button.

### Set up Pingdom

On [Pingdom](https://my.pingdom.com/newchecks/checks), create a new uptime check to point to the
new deploy's front page. It should check once a minute, alert after 2 minutes down; and the Slack
webhook integration should be checked if you use Slack to manage alerts.

### Add a help link to Heroku config

If you have a help page for your deploy, you can add a link to it in the menu bar by
setting the `HELP_LINK` config variable like so:

```bash
heroku set:config HELP_LINK='https://example.com/' --app [APP-NAME]
```

### Add an exit survey and responses

When clients are deactivated in ClientComm, the user is presented with a survey that must be filled
out before the deactivation can proceed. To create this survey on your deploy, start up a rails
console on the remote server with the Heroku CLI:

```bash
heroku run rails c --app [APP-NAME]
```

Then create a survey question:

```ruby
SurveyQuestion.create!(text: 'What was the outcome for this client?')
```

...and the multiple-choice responses:

```ruby
question = SurveyQuestion.last
response_texts = ['Successful termination', 'Unsuccessful termination', 'Other / not applicable']
response_texts.each do |text|
  SurveyResponse.create!(survey_question: question, text: text)
end
```
