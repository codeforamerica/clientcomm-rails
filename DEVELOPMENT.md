# Development Setup

### Requirements
1. Install Ruby with your ruby version manager of choice, like [rbenv](https://github.com/rbenv/rbenv)
or [RVM](https://github.com/codeforamerica/howto/blob/master/Ruby.md)
2. Check the ruby version in `.ruby-version` and ensure you have it installed locally e.g. `rbenv install 2.4.5`
3. [Install Postgres](https://github.com/codeforamerica/howto/blob/master/PostgreSQL.md). If setting
up [Postgres.app](https://postgresapp.com/), you will also need to add the binary to your path. e.g.
add to your `~/.zshrc` or `~/.bashrc`:
```
export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"
```

## Application Setup

1. Install [bundler](https://bundler.io/) (the [latest Heroku-compatible version](https://devcenter.heroku.com/articles/ruby-support#libraries)): `gem install bundler -v 1.15.2`
2. Install other requirements: `bundle install`

    If you installed Postgres.app, you may need to install the `pg` gem independently with this command:

    ```
    gem install pg -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config
    ```
3. Create the databases:
```
rails db:create
```
4. Apply the schema to the databases:
```
rails db:schema:load RAILS_ENV=development
rails db:schema:load RAILS_ENV=test
```
5. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli#download-and-install)
6. Copy `.env.example` to `.env` and fill in the relevant values.
7. Start the server with `heroku local`. Take note of the port the server is running on, which may be
set with the `PORT` variable in your `.env` file.

## Setting Up Twilio and ngrok

In order to send and receive messages when running ClientComm on your computer, you'll need to set up
an account and buy a phone number on [Twilio](https://www.twilio.com/). The Twilio API expects
your application to have publicly-accessible endpoints for incoming messages, message status updates,
and phone calls; we use [ngrok](https://ngrok.com/) to create a secure public URL that Twilio can use
to communicate with the ClientComm application running on your computer.

1. [Buy an SMS-capable phone number on Twilio.](https://support.twilio.com/hc/en-us/articles/223135247-How-to-Search-for-and-Buy-a-Twilio-Phone-Number-from-Console)
2. Install [ngrok](https://ngrok.com/). Install with [Homebrew](https://brew.sh/): `brew cask install ngrok`
or [download the binary](https://ngrok.com/download) and [create a symlink](https://gist.github.com/wosephjeber/aa174fb851dfe87e644e#creating-a-symlink-to-ngrok).
3. Start ngrok by entering `ngrok http 3000` in the terminal to start a tunnel (replace `3000` with
the port your application is running on if necessary). You should see an ngrok url with a unique ID
displayed, e.g. `https://e595b046.ngrok.io`.
4. When your Twilio number receives an sms message or phone call, it needs to know where to route it.
ClientComm has endpoints to receive Twilio webhooks at `/incoming/sms/` and `/incoming/voice/`. Click
on your phone number in the Twilio web interface and enter the `https://[NGROK ID].ngrok.io/incoming/sms/`
URL in the *A MESSAGE COMES IN* field, under *Messaging*, and the `https://[NGROK ID].ngrok.io/incoming/voice/`
URL in the *A CALL COMES IN* field, under *Voice & Fax* (see the image below).

![Twilio's interface for entering endpoint URLs](/public/twilio_develop.png)

## Testing

- [Phantom](http://phantomjs.org/) is required to run some of the feature tests. [Download](http://phantomjs.org/download.html) or install with [Homebrew](https://brew.sh/): `brew install phantomjs`
- [ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/) is also required to run some of the feature tests. [Download](https://sites.google.com/a/chromium.org/chromedriver/downloads) or install with [Homebrew](https://brew.sh/): `brew cask install chromedriver`
- Run the test suite: `bin/rspec` or `bundle exec rspec`. For more detailed logging use `LOUD_TESTS=true bin/rspec`.

# Production Deploy

See [the production deploy README.](deploy/terraform/README.md)


