CREATE EXTENSION pgcrypto;

CREATE TABLE users (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL,
  username varchar(25) NOT NULL UNIQUE,
  pswhash text NOT NULL,
  --- salt uuid NOT NULL DEFAULT UUID_GENERATE_V4(), ---
  profile_picture bytea
);

 CREATE TABLE events (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title text,
  description text,
  location text,
  date date NOT NULL,
  time time NOT NULL,
  creator_id integer NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE attendee_status_enum AS ENUM ('Y', 'M', 'N');

CREATE TABLE events_participants (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  event_id integer NOT NULL REFERENCES events(id),
  participant_id integer NOT NULL REFERENCES users(id),
  attendee_status attendee_status_enum NOT NULL,
  UNIQUE(event_id, participant_id)
);