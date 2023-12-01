require "pg"
require "time"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "azeema")
    @logger = logger
  end

  def create_new_user(name, username, password)
    sql_create_new_user = <<-SQL
      INSERT INTO users (name, username, pswhash) VALUES
        ($1, $2, crypt($3, gen_salt('bf')))
    SQL
    query(sql_create_new_user, name, username, password)
  end

  def create_new_event(title, description, location, date, time, creator_id)
    sql_create_new_event = <<-SQL
      INSERT INTO events (title, description, location, date, time, creator_id) VALUES
        ($1, $2, $3, $4, $5, $6)
    SQL
    query(sql_create_new_event, title, description, location, date, time, creator_id)
  end

  def sign_in(username, password)
    sql_sign_in = <<-SQL
      SELECT id, username FROM users 
        WHERE username = $1 AND 
        pswhash = crypt($2, pswhash)
    SQL

    match = query(sql_sign_in, username, password).first

    match ? { username: match["username"], id: match["id"].to_i } : nil
    # match.first ? match.first["username"] : nil
  end

  def all_user_events(user)
    sql_all_events_query = <<-SQL
      SELECT title, date, id FROM events WHERE creator_id IN (
        SELECT users.id FROM users WHERE username = $1
      );
    SQL
    events = query(sql_all_events_query, user)

    events.map do |event|
      { title: event["title"],
        date: event["date"],
        id: event["id"] }
    end
  end

  def single_event(event_id)
    sql_single_event_query = <<-SQL
      SELECT * FROM events WHERE id = $1
    SQL
    event = query(sql_single_event_query, event_id).first
    
    { title: event["title"],
      description: event["description"],
      locaiton: event["location"],
      date: event["date"],
      time: event["time"] }
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end

