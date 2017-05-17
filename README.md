# clientcomm-rails

[![CircleCI](https://circleci.com/gh/codeforamerica/clientcomm-rails.svg?style=svg)](https://circleci.com/gh/codeforamerica/clientcomm-rails)

A rails port/reimagining of [ClientComm](https://github.com/slco-2016/clientcomm).

## Installation
### Requirements
1. Install Ruby with your ruby version manager of choice, using [rbenv](https://github.com/rbenv/rbenv) or [RVM](https://github.com/codeforamerica/howto/blob/master/Ruby.md)
1. Check the ruby version in `.ruby-version` and ensure you have it installed locally e.g. `rbenv install 2.4.0`
1. Install postgres - [howto](https://github.com/codeforamerica/howto/blob/master/PostgreSQL.md). If setting up Postgres.app, you will also need to add the binary to your path. e.g. Add to your `~/.bashrc`:
`export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin"`

## Setup

1. Install [bundler](https://bundler.io/): `gem install bundler`
1. Install other requirements: `bundle install`
1. Create the databases: `rails db:create`
1. Apply the schema to the databases:
```
rails db:schema:load RAILS_ENV=development
rails db:schema:load RAILS_ENV=test
```
1. Start the server: `rails s`

## Testing

- Test suite: `bin/rspec`. For more detailed logging use `bin/rspec LOUD_TESTS=true`.
- File-watcher: `bin/guard` when running will automatically run corresponding specs when a file is edited.

## Contact

Tomas Apodaca ( @tmaybe )
