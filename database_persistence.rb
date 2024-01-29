require "pg"
require "time"
require "date"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
        # PG.connect(ENV['DATABASE_URL'])
        PG.connect(dbname: 'azeema')
      else
        # PG.connect(ENV['DATABASE_URL'])
        PG.connect(dbname: 'azeema')
      end
    @logger = logger
  end

  def create_new_user(name, username, password, session)
    sql_create_new_user = <<-SQL
      INSERT INTO users (name, username, pswhash) VALUES
        ($1, $2, crypt($3, gen_salt('bf')))
    SQL

    begin
      query(sql_create_new_user, name, username, password)
    rescue PG::Error => err
      session[:error] = error_message(err.to_s, username)
    end
  end

  def create_new_event(title, description, location, date, time_start, time_end, creator_id, image_name=nil)
    sql_create_new_event = <<-SQL
      INSERT INTO events (title, description, location, date, time_start, time_end, creator_id) VALUES
        ($1, $2, $3, $4, $5, $6, $7) RETURNING id;
    SQL
    event_id = query(sql_create_new_event, title, description, location, date, time_start, time_end, creator_id).first["id"]

    sql_event_picture = <<-SQL
      UPDATE events SET event_picture = $1 WHERE id = $2;
    SQL
    if image_name
      query(sql_event_picture, image_name, event_id)
    end

    return event_id
  end

  def edit_event(title, description, location, date, time_start, time_end, event_id, image_name=nil)
    sql_edit_event = <<-SQL
      UPDATE events SET
        title = $1,
        description = $2,
        location = $3,
        date = $4,
        time_start = $5,
        time_end = $6
      WHERE id = $7;
    SQL
    query(sql_edit_event, title, description, location, date, time_start, time_end, event_id)

    sql_event_picture = <<-SQL
      UPDATE events SET event_picture = $1 WHERE id = $2;
    SQL
    if image_name
      query(sql_event_picture, image_name, event_id)
    end
  end

  def delete_event(event_id)
    sql_delete_event = <<-SQL
      DELETE FROM events WHERE id = $1
    SQL
    query(sql_delete_event, event_id)
  end

  def sign_in(username, password)
    sql_sign_in = <<-SQL
      SELECT 
        id, 
        username 
      FROM users 
        WHERE username = $1 
          AND pswhash = crypt($2, pswhash)
    SQL

    match = query(sql_sign_in, username, password).first

    match ? { username: match["username"], id: match["id"].to_i } : nil
    # match.first ? match.first["username"] : nil
  end

  def hosting_events(creator_id)
    sql_hosting_query = <<-SQL
      SELECT 
        title, 
        date, 
        id 
      FROM events 
        WHERE creator_id IN (
          SELECT 
            users.id 
          FROM users 
            WHERE users.id = $1
        );
    SQL
    events = query(sql_hosting_query, creator_id)

    events.map do |event|
      { title: event["title"],
        date: event["date"],
        id: event["id"] }
    end
  end

  def get_attending_status(event_id, participant_id)
    sql_check_status_query = <<-SQL
      SELECT 
        attendee_status 
      FROM events_participants 
        WHERE event_id = $1 
        AND participant_id = $2
    SQL
    status = query(sql_check_status_query, event_id, participant_id)

    status.first ? status.first["attendee_status"] : nil
  end

  def set_attending_status(event_id, participant_id, new_status)
     current_status = get_attending_status(event_id, participant_id)

    sql_set_new_status_query = <<-SQL
      INSERT INTO events_participants (event_id, participant_id, attendee_status)
        VALUES ($1, $2, $3)
    SQL
    sql_update_status_query = <<-SQL
      UPDATE events_participants 
      SET attendee_status = $3
        WHERE event_id = $1
        AND participant_id = $2 
    SQL

    if current_status
      query(sql_update_status_query, event_id, participant_id, new_status)
    else
      query(sql_set_new_status_query, event_id, participant_id, new_status)
    end
  end

  def all_participants(event_id)
    sql_all_participants_query = <<-SQL
      SELECT 
        participant_id AS "id", 
        attendee_status AS "status"
      FROM events_participants 
        WHERE event_id = $1
    SQL
    participants = query(sql_all_participants_query, event_id)

    participants.map do |participant|
      { id: participant["id"], 
        username: get_username_from_id(participant["id"]),
        status: participant["status"] }
    end
  end

  def single_event(event_id)
    sql_single_event_query = <<-SQL
      SELECT * FROM events WHERE id = $1
    SQL
    creator = get_event_creator(event_id)
    event = query(sql_single_event_query, event_id).first
    
    { title: event["title"],
      id: event_id,
      creator: creator[:username],
      creator_id: creator[:creator_id],
      creator_pfp: get_pfp_url(creator[:creator_id]),
      description: event["description"],
      location: event["location"],
      date: event["date"],
      time_start: event["time_start"],
      time_end: event["time_end"],
      event_picture: get_event_picture(event["event_picture"]) }
  end

  # Get all events the user partakes in (hosting/attending)
  def all_events(user_id, limit=4)
    sql_all_events_query = <<-SQL
      SELECT DISTINCT 
        events.id, 
        title, 
        date, 
        time_start,
        time_end, 
        creator_id, 
        event_picture 
      FROM events 
        LEFT JOIN events_participants 
          ON events.id = event_id 
        WHERE creator_id = $1 OR participant_id = $1
        ORDER BY date DESC, time_start ASC
        LIMIT $2
    SQL
    events = query(sql_all_events_query, user_id, limit)

    events.map do |event|
      { id: event["id"], 
        title: event["title"],
        date: event["date"],
        time_start: event["time_start"],
        time_end: event["time_end"],
        creator_id: event["creator_id"],
        event_picture: get_event_picture(event["event_picture"]) }
    end
  end

  def hosting_events(user_id, limit=4)
    sql_hosting_events_query = <<-SQL
      SELECT DISTINCT 
        events.id, 
        title, 
        date, 
        time_start,
        time_end, 
        creator_id, 
        event_picture 
      FROM events 
        WHERE creator_id = $1
        ORDER BY date DESC, time_start ASC
        LIMIT $2
    SQL
    events = query(sql_hosting_events_query, user_id, limit)

    events.map do |event|
      { id: event["id"], 
        title: event["title"],
        date: event["date"],
        time_start: event["time_start"],
        time_end: event["time_end"],
        creator_id: event["creator_id"],
        event_picture: get_event_picture(event["event_picture"]) }
    end
  end

  def attended_events(user_id, limit=4)
    sql_attending_events_query = <<-SQL
      SELECT DISTINCT 
        events.id, 
        title, 
        date, 
        time_start,
        time_end,
        creator_id, 
        event_picture 
      FROM events 
        LEFT JOIN events_participants 
          ON events.id = event_id 
        WHERE (participant_id = $1 OR creator_id = $1)
          AND date < $2
        ORDER BY date DESC, time_start ASC
        LIMIT $3
    SQL
    events = query(sql_attending_events_query, user_id, Date.today.to_s, limit)

    events.map do |event|
      { id: event["id"], 
        title: event["title"],
        date: event["date"],
        time_start: event["time_start"],
        time_end: event["time_end"],
        creator_id: event["creator_id"],
        event_picture: get_event_picture(event["event_picture"]) }
    end
  end

  def upcoming_events(user_id, limit=4)
    sql_upcoming_events_query = <<-SQL
      SELECT DISTINCT 
        events.id, 
        title, 
        date, 
        time_start,
        time_end, 
        creator_id, 
        event_picture 
      FROM events 
        LEFT JOIN events_participants 
          ON events.id = event_id 
        WHERE (participant_id = $1 OR creator_id = $1)
          AND date >= $2
        ORDER BY date DESC, time_start ASC
        LIMIT $3
    SQL
    events = query(sql_upcoming_events_query, user_id, Date.today.to_s, limit)

    events.map do |event|
      { id: event["id"], 
        title: event["title"],
        date: event["date"],
        time_start: event["time_start"],
        time_end: event["time_end"],
        creator_id: event["creator_id"],
        event_picture: get_event_picture(event["event_picture"]) }
    end
  end

  def get_event_creator(event_id)
    sql_event_creator_query = <<-SQL
      SELECT creator_id, 
        username 
      FROM events 
        JOIN users 
          ON creator_id = users.id 
        WHERE events.id = $1;
    SQL
    creator = query(sql_event_creator_query, event_id).first

    creator ? {creator_id: creator["creator_id"], username: creator["username"]} : nil
  end

  def set_event_picture_filename(event_it, filename)

  end

  def set_pfp_filename(user_id, filename)
    sql_get_pfp_query = <<-SQL
      SELECT profile_picture FROM users WHERE id = $1;
    SQL
    get = query(sql_get_pfp_query, user_id)

    sql_set_pfp_query = <<-SQL
      UPDATE users SET profile_picture = $1 WHERE id = $2;
    SQL
    puts "------------------"
    get.ntuples

    if get.tuple(0)[0] == nil
      query(sql_set_pfp_query, filename, user_id)
    end
  end

  def get_pfp_url(user_id)
    sql_get_pfp_query = <<-SQL
      SELECT profile_picture FROM users WHERE id = $1;
    SQL
    pfp = query(sql_get_pfp_query, user_id).first["profile_picture"]

    pfp ? "https://azeema.s3.us-west-1.amazonaws.com/#{pfp}" : "/images/default-pfp.svg"
  end

  def event_exists?(event_id)
    sql_event_exists_query = <<-SQL
      SELECT 1 
      FROM events 
        WHERE id = $1;
    SQL
    exists = query(sql_event_exists_query, event_id).first

    exists ? true : false
  end

  def get_event_picture_filename(event_id)
    sql_get_ep_filename = <<-SQL
      SELECT event_picture 
      FROM events 
        WHERE id = $1;
    SQL
    filename = query(sql_get_ep_filename, event_id).first

    filename ? filename["event_picture"] : nil
  end

  def get_user_stats(user_id)
    sql_num_hosted_query = <<-SQL
      SELECT COUNT(events.creator_id) AS "hosted"
      FROM events 
        WHERE creator_id = $1
    SQL
    sql_num_attended_query = <<-SQL
      SELECT COUNT(participant_id) AS "attended"
      FROM events_participants
        WHERE participant_id = $1
    SQL
    hosted = query(sql_num_hosted_query, user_id).first
    attended = query(sql_num_attended_query, user_id).first

    { hosted: hosted["hosted"], attended: attended["attended"] }
  end

  def get_full_name_from_id(user_id)
    sql_full_name_query = <<-SQL
      SELECT name as "full_name"
      FROM users
        WHERE id = $1
    SQL

    query(sql_full_name_query, user_id).first
  end

  private

  def error_message(message, username)
    username_length_errors = ["users_username_check", "varying(25)"]
    username_char_errors = ["users_username_no_special_chars"]
    username_unique_errors = ["users_username_key"]
    name_length_errors =  ["varying(50)", "users_name_check"]
    name_char_errors = ["users_name_only_alphabets"]

    if username_length_errors.any? { |error| message.include? error }
      "Your username must be between 3 and 25 characters long."
    elsif name_length_errors.any? { |error| message.include? error }
      "Your name may only be between 3 and 50 characters long."
    elsif username_char_errors.any? { |error| message.include? error }
      "Your name may only include English letters and numbers."
    elsif name_char_errors.any? { |error| message.include? error }
      "Your name may only include letters of the English alphabet."
    elsif message.include? "users_username_key"
      "The username '#{username}' is already taken."
    else
      message
    end
  end

  def query(statement, *params)
    # @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def get_username_from_id(user_id)
    sql_username_query = <<-SQL
      SELECT username FROM users WHERE id = $1
    SQL
    query(sql_username_query, user_id).first["username"]
  end

  def get_event_picture(filename)
    filename ? "https://azeema.s3.us-west-1.amazonaws.com/#{filename}" : nil
  end
end

