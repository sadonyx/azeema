# Project Description

The Azeema project is a web application that allows users to host their events’ details and keep track of the events’ invitees and attendees.

**Note**: There is another version of this project that utilizes `aws` to store and load images to and from an S3 bucket. This version of the project is a stripped down version in order to ensure an easier grading process.

# System Requirements

- Ruby Version
    - **3.2.2**
- Browser
    - **Google Chrome v.120.0.6099.129 (Official Build) (arm64*)**
- Postgres
    - **v. 15.5**

# Starting the Application

Once the project folder has been downloaded onto your system, navigate to the project directory folder in the command line. Then, create a database called `azeema` using the postgres command `createdb azeema`. Once the database was successfully created, you can either load an empty schema **OR** a populated SQL seed with either respective command:
  - `psql azeema < schema.sql`
  - `psql azeema < seed.sql`

  **NOTE**: You cannot run both of these commands one after the other. If you would like to reset the database, you must execute the command `dropdb azeema` in the command line and then start from the beginning of the database instructions.

Once you have the database setup, ensure you are still directed in the project directory in the command line. Then, execute the command `bundle install` to install all of the required gems to run the project that are listed in the `Gemfile`. Once all Ruby gems have successfully installed without any errors, you may execute the command `ruby azeema.rb` in the command line to launch the Sinatra server.
**NOTE**: Originally, I stated that you should delete the `Gemfile.lock` file, however this should not be the case, as this file ensures the exact same versions of all the gems are used when any other machine executes `bundle install`.

## Login Credentials

- Username: adnan ; Password: adnan (pre-populated)
- Username: admin ; Password: admin (pre-populated)

Feel free to create a new user if you would like. Passwords are encrypted using Postgres `pgcrypto` to create a password hash that is stored in the database (plain password text should never be stored in the database). For password validation, the inputted password is simply run through the same hashing algorithm and the new password hash is compared to the one stored in the db.

# Database

The `azeema` database schema consists of three tables: `events`, `users`, and `events_participants`. The `users` and `events` tables have a one-to-many relationship, in which a `user` can create/host many events, and an `event` can only have one creator. This is demonstrated through the `creator_id` column in the `events` table which is a foreign key that references the `[users.id](http://users.id)` column.

At the same time, the `users` and `events` tables also have a many-to-many relationship through the use of the `events_participants` JOIN table, in which an event can have multiple unique participants with an attending status for that event, and a user can have an attending status for multiple unique events.

# /events

This page loads partials through AJAX calls.

## All Events

The `All Events` partial will display all the events a user has interacted with, whether the user is hosting/has hosted the event or is attending/has attended the event. It is displayed in descending chronological order (future → past).

## Upcoming

The `Upcoming` partial will display all future events a user has submitted a participation status for. It is displayed in descending chronological order (future → present).

## Hosting

The `Hosting` partial will display all events a user is hosting/has hosted. The ‘host’ of an event is merely the event’s creator. It is displayed in descending chronological order (future → past).

## Attended

The `Attended` partial will display all events that have passed and the user has attended. It is displayed in descending chronological order (past → and so on).

### Pagination

For each of the listed partials, scrolling to the end of the loaded events list will render a `Load More` button, which will make an AJAX call to the server with an increase in the `LIMIT` (increments of 1) of the SQL query. The logic for this is located in the `filterEvents.js` file.

# /e/:id

A `get` request to this url directs Sinatra to fetch the data for a specific event from the SQL database. The data that is fetched includes the `title`, `date`, `start_time`, `end_time`, `creator_id`, `location`, and `description` of the event. This data is fetched from the `events` table of the `azeema` database.  In order to get the creator’s name of the event, Sinatra makes an SQL call to fetch the `username` from the `users` table where the `creator_id` == `users.id`.

## Sanitization

All user-inputted data is sanitized by setting Sinatra’s `:escape_html` parameter to `true`. The only issue I ran into with this is formatting the `description` data of an event, which utilizes new-lines and line-breaks. In order to keep the integrity of the description’s formatting without bypassing any sanitation, I call the `format_description` helper method to render a description with all of it’s new lines in tact.

## Validation

Essentially, all input is considered valid except for blank text.

## Participants

The participants section of this page is an erb partial that is loaded through an AJAX call and is refreshed every time the user changes their status.