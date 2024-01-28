CREATE EXTENSION pgcrypto;

CREATE TABLE users (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name varchar(50) NOT NULL CHECK(LENGTH(name) >= 3 AND LENGTH(name) <= 50),
  username varchar(25) NOT NULL UNIQUE CHECK(LENGTH(username) >= 3 AND LENGTH(username) <= 25),
  pswhash text NOT NULL,
  date_joined timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  profile_picture text DEFAULT NULL
);

ALTER TABLE users
ADD CONSTRAINT users_username_no_special_chars
       CHECK (username NOT LIKE '%[^A-Z0-9]%') ;

ALTER TABLE users 
ADD CONSTRAINT users_name_only_alphabets 
       CHECK (name NOT LIKE '%[^A-Z]%');

 CREATE TABLE events (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title text,
  description text,
  location text,
  date date NOT NULL,
  time_start time NOT NULL,
  time_end time NOT NULL,
  capacity numeric NOT NULL DEFAULT 'infinity'::numeric,
  creator_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  event_picture text default NULL
);

CREATE TYPE attendee_status_enum AS ENUM ('Y', 'M', 'N');

CREATE TABLE events_participants (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  event_id integer NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  participant_id integer NOT NULL REFERENCES users(id),
  attendee_status attendee_status_enum NOT NULL,
  UNIQUE(event_id, participant_id)
);