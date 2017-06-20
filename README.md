# clientcomm-rails

[![CircleCI](https://circleci.com/gh/codeforamerica/clientcomm-rails.svg?style=svg)](https://circleci.com/gh/codeforamerica/clientcomm-rails)
[![Code Climate](https://codeclimate.com/github/codeforamerica/clientcomm-rails/badges/gpa.svg)](https://codeclimate.com/github/codeforamerica/clientcomm-rails)
[![Test Coverage](https://codeclimate.com/github/codeforamerica/clientcomm-rails/badges/coverage.svg)](https://codeclimate.com/github/codeforamerica/clientcomm-rails/coverage)

A rails port/reimagining of [ClientComm](https://github.com/slco-2016/clientcomm).

## Installation
### Requirements
1. Install Ruby with your ruby version manager of choice, using [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://github.com/codeforamerica/howto/blob/master/Ruby.md)
2. Check the ruby version in `.ruby-version` and ensure you have it installed locally e.g. `rbenv install 2.4.0`
3. Install postgres - [howto](https://github.com/codeforamerica/howto/blob/master/PostgreSQL.md). If setting up Postgres.app, you will also need to add the binary to your path. e.g. Add to your `~/.bashrc`:
`export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"`

## Setup

1. Install [bundler](https://bundler.io/): `gem install bundler`
2. Install other requirements: `bundle install`
3. Create the databases: `rails db:create`
4. Apply the schema to the databases:
```
rails db:schema:load RAILS_ENV=development
rails db:schema:load RAILS_ENV=test
```
5. Start the server: `rails s`

## Setting Up Twilio

1. Buy a Twilio number. You can use their console, or this [gist](https://gist.github.com/cweems/e3fb8ab69c6e0776e492d88672a4ded9).

2. Install ngrok. You can [download the binary](https://gist.github.com/wosephjeber/aa174fb851dfe87e644e) and create a symlink, or use `npm install -g ngrok` if you are running NPM on your machine.

3. Start ngrok: run `ngrok http 3000` to start a tunnel to port 3000. You should see an ngrok url displayed, e.g. `https://e595b046.ngrok.io`.

4. Add your ngrok url as the sms callback for Twilio. First, [use this script](https://gist.github.com/cweems/83980eaec208941256da8823ebf71a5e) to find your phone number's SID. Then use [this script](https://gist.github.com/cweems/88560859525ddd4b19e0eaf71f5bbd17) to update your Twilio callback with your ngrok url.

5. Start your server using `heroku local` and open your browser to the ngrok url (not localhost). Note: `PORT` must be set to 3000 in your `.env` file, otherwise heroku will default to 5000.

## Testing

- Test suite: `bin/rspec`. For more detailed logging use `bin/rspec LOUD_TESTS=true`.
- File-watcher: `bin/guard` when running will automatically run corresponding specs when a file is edited.
- Phantom is required to run tests: `brew install phantom`

## Contact

Tomas Apodaca ( @tmaybe )
