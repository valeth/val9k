<a href="https://discordbots.org/bot/321450850629189633" >
  <img src="https://discordbots.org/api/widget/status/321450850629189633.svg?noavatar=true" alt="Discord Music Bot" />
</a>

# VAL9000

## Requirements
- Ruby
- PostgreSQL server
- Redis server (for YouTube notifications)

## Setup

Run `bundle install --with=webserver` to install all necessary dependencies.

Copy the `.env.example` file to a file named `.env` and replace the Discord token,
bot prefix etc. with your settings.

Make sure `postgres` is running and set up the database with `rake db:setup`.

Run the bot with `rake run` (this will automatically run database migrations if necessary).

## Bugs

Report issues on the [GitLab issue tracker](https://gitlab.com/valeth/val9k/issues).
