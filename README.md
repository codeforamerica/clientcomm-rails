# clientcomm

[![CircleCI](https://circleci.com/gh/codeforamerica/clientcomm-rails.svg?style=svg)](https://circleci.com/gh/codeforamerica/clientcomm-rails)
[![Code Climate](https://codeclimate.com/github/codeforamerica/clientcomm-rails/badges/gpa.svg)](https://codeclimate.com/github/codeforamerica/clientcomm-rails)
[![Test Coverage](https://codeclimate.com/github/codeforamerica/clientcomm-rails/badges/coverage.svg)](https://codeclimate.com/github/codeforamerica/clientcomm-rails/coverage)

The best way to keep clients compliant with the terms of their probation is to check in with them often. ClientComm makes it easy to keep in touch. ClientComm lets case managers send clients text messages from their computers. Conversations are kept together even if the client changes phone numbers. ClientComm triages texts based on communication history and authentication, and assigns messages to the right case.

Read more: ClientComm.org

# Context

Every county struggles with individuals cycling in and out of jail due to missing court appearances or court-ordered treatment. Those jail stays are expensive, inefficient and, most of all, don't help address the person's underlying issues. Probation case managers and pretrial case managers juggle clients who are often dealing with other things like unstable family, housing and employment situations; changing addresses and phone numbers. All of these things makes it hard to stay in touch.

Case managers know the best way to keep their clients compliant with the terms of their probation is to check in with them often, remind them of their commitments, and help them with problems that arise. Stakes are high—if they don’t comply with probation, they may go to jail.

ClientComm started as a [2016 Code for America fellowship project](https://github.com/slco-2016/clientcomm) and is now a central part of Code for America's product work on [Safety and Justice](https://www.codeforamerica.org/focus-areas/safety-and-justice)

## Installation
### Requirements
1. Install Ruby with your ruby version manager of choice, like [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://github.com/codeforamerica/howto/blob/master/Ruby.md)
2. Check the ruby version in `.ruby-version` and ensure you have it installed locally e.g. `rbenv install 2.4.0`
3. [Install Postgres](https://github.com/codeforamerica/howto/blob/master/PostgreSQL.md). If setting up Postgres.app, you will also need to add the binary to your path. e.g. Add to your `~/.bashrc`:
`export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"`

## Setup

1. Install [bundler](https://bundler.io/) (the latest Heroku-compatible version): `gem install bundler -v 1.15.1`
2. Install other requirements: `bundle install`
3. Create the databases: `rails db:create`
4. Apply the schema to the databases:
```
rails db:schema:load RAILS_ENV=development
rails db:schema:load RAILS_ENV=test
```
5. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli#download-and-install)
6. Copy `.env.example` to `.env` and fill in the relevant values.
7. Start the server with `heroku local`. Take note of the port the server is running on, which may be set with the `PORT` variable in your `.env` file.

## Setting Up Twilio

1. Buy an SMS-capable phone number on [Twilio](https://www.twilio.com/). You can use [the web interface](https://www.twilio.com/console/phone-numbers/search), or [this script](https://gist.github.com/cweems/e3fb8ab69c6e0776e492d88672a4ded9).
2. Install [ngrok](https://ngrok.com/). If you are running [npm](https://www.npmjs.com/), install with `npm install -g ngrok`. Otherwise [download the binary](https://ngrok.com/download) and [create a symlink](https://gist.github.com/wosephjeber/aa174fb851dfe87e644e#creating-a-symlink-to-ngrok).
3. Start ngrok by entering `ngrok http 3000` in the terminal to start a tunnel (replace `3000` with the port your application is running on if necessary). You should see an ngrok url displayed, e.g. `https://e595b046.ngrok.io`.
4. When your Twilio number receives an sms message, it needs to know where to send it. The application has an endpoint to receive Twilio webhooks at, for example, `https://e595b046.ngrok.io/incoming/sms/`. Click on your phone number in [the Twilio web interface](https://www.twilio.com/console/phone-numbers/incoming) and enter this URL (with your unique ngrok hostname) in the *A MESSAGE COMES IN* field, under *Messaging*.
  
   Alternately, you can use [this script](https://gist.github.com/cweems/83980eaec208941256da8823ebf71a5e) to find your phone number's SID, then use [this script](https://gist.github.com/cweems/88560859525ddd4b19e0eaf71f5bbd17) to update the Twilio callback with your ngrok url.

## Testing

- [Phantom](http://phantomjs.org/) is required to run some of the feature tests. [Download](http://phantomjs.org/download.html) or install with [Homebrew](https://brew.sh/): `brew install phantom`
- Test suite: `bin/rspec`. For more detailed logging use `LOUD_TESTS=true bin/rspec`.
- File-watcher: `bin/guard` when running will automatically run corresponding specs when a file is edited.

## How to restore DB from backup

1. Get the public URL for the databse backup: `heroku pg:backups:url --app [APP_NAME]` This should return a long AWS url for the most recent backup.
1. Restore the DB: `heroku pg:backups:restore [previously found url] DATABASE_URL --app [APP_NAME]` Do not forget to correctly escape the db url, either with backslashes or with single quotes.

## Contact

Tomas Apodaca ( @tmaybe )
