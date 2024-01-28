require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'date'
require 'time'
require 'tempfile'
require 'mini_magick'
require 'add_to_calendar'

require_relative "database_persistence.rb"
require_relative "session_persistence.rb"
require_relative "aws_persistence.rb"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
  set :public_folder, __dir__ + '/public'
  set :port, 8080
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
  also_reload "session_persistence.rb"
  also_reload "aws_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)
  @user_session = session[:logged_in]
  if !@user_session.instance_of? SessionPersistence
    session[:logged_in] = SessionPersistence.new
  elsif @user_session.valid_token? != true
    session[:logged_in] = SessionPersistence.new
  end
  @user_session = session[:logged_in]
  @s3 = AwsSession.new
  if is_logged_in?
    @pfp = @storage.get_pfp_url(@user_session.id)
  end
end

not_found do
  if is_logged_in?
    redirect "/events"
  else
    status 404
    erb :oops
  end
end

get "/" do
  redirect_to_login
  # Eventually will lead to landing page...
  redirect "/events"
end

get "/events" do
  redirect_to_login("You must be logged in to view your events.")

  @events = @storage.all_events(@user_session.id)
  @status = "all"
  
  erb :events, layout: :layout
end

get "/profile" do
  redirect_to_login("You must be logged in to view your profile.")

  @user_stats = @storage.get_user_stats(@user_session.id)
  erb :profile
end

post "/profile" do
  username = @user_session.username
  image = handle_image_file(params, username)
  p image

  @storage.set_pfp_filename(@user_session.id, image[:image_name])
  @s3.put_profile_picture(image[:path], image[:image_name])

  redirect "/profile"
end

# Load user signup page
get "/create-account" do
  erb :new_user
end

# Create new user
post "/create-account" do
  name = params[:name].strip
  username = params[:username].downcase.gsub(/\s+/, "")
  password = params[:password].strip
  @storage.create_new_user(name, username, password, session)

  if session[:error]
    erb :new_user
  else
    redirect "/login"
  end
end

# Load Login Page
get "/login" do
  if is_logged_in?
    redirect "/events"
  else
    erb :login
  end
end

# Send login information for auth
post "/login" do
  username = params[:username]

  auth = @storage.sign_in(username, params[:password])

  if auth
    @user_session.sign_in(auth[:username], auth[:id])
    redirect "/"
  else
    session[:error] = "Invalid username or password."
    redirect "/login"
  end
end

post "/logout" do
  @user_session.sign_out
  redirect "/"
end

get "/events/create" do
  redirect_to_login("You must be logged in to create an event.")

  erb :new_event
end

post "/events/create" do
  redirect_to_login("You must be logged in to create an event.")
  event_validation(params)

  username = @user_session.username
  user_id = @user_session.id
  image = handle_image_file(params, username)

  if image
    event_id = @storage.create_new_event(params[:title].strip, params[:description].strip, params[:location].strip, params[:date], params[:'time-start'], params[:'time-end'], user_id, image[:image_name])
    @s3.put_event_picture(image[:path], image[:image_name])
  else
    event_id = @storage.create_new_event(params[:title].strip, params[:description].strip, params[:location].strip, params[:date], params[:'time-start'], params[:'time-end'], user_id)
  end

  session[:success] = "Your event '#{params[:title]}' is now live!"
  redirect "/e/#{event_id}"
end

get "/e/:event_id" do
  event_id = params[:event_id]
  event_exists?(event_id)

  @current_status = @storage.get_attending_status(event_id, @user_session.id)
  @event = @storage.single_event(event_id)
  @participants = @storage.all_participants(event_id)

  organizer_name = @storage.get_full_name_from_id(@event[:creator_id])

  @cal = AddToCalendar::URLs.new(
    start_datetime: format_datetime(@event[:date], @event[:time_start]),
    end_datetime: format_datetime(@event[:date], @event[:time_end]),
    title: @event[:title],
    timezone: 'America/Los_Angeles', # Planning to later incorporate a method to find user's personalized timezone
    location: @event[:location],
    url: "https://azeema-project.fly.dev/e/#{event_id}",
    description: @event[:description],
    add_url_to_description: false,
    # organizer: {
    #   name: organizer_name,
    #   email: ""
    # }
  )

  erb :event
end

post "/e/:event_id" do
  redirect_to_login("You must be logged in to set your attending status.")

  event_id = params[:event_id]
  participant_id = @user_session.id
  @storage.set_attending_status(event_id, participant_id, params[:attending])
end

get "/e/:event_id/edit" do
  redirect_to_login("You must be logged in to edit events you own.")

  event_id = params[:event_id]
  event_exists?(event_id)
  authorized_to_edit?(event_id)
  @event = @storage.single_event(event_id)
  erb :edit_event
end

post "/e/:event_id/edit" do
  redirect_to_login("You must be logged in to edit events you own.")
  event_validation(params)

  event_id = params[:event_id]
  username = @user_session.username
  image = handle_image_file(params, username, event_id)

  title = params[:title].strip
  description = params[:description].strip
  location = params[:location].strip
  date = params[:date]
  time_start = params[:'time-start']
  time_end = params[:'time-end']
  
  if image
    @storage.edit_event(title, description, location, date, time_start, time_end, event_id, image[:image_name])
    @s3.put_event_picture(image[:path], image[:image_name])
  else
    @storage.edit_event(title, description, location, date, time_start, time_end, event_id)
  end
  
  redirect "/e/#{event_id}"
end

post "/e/:event_id/delete" do
  event_id = params[:event_id]
  @storage.delete_event(event_id)
  session[:success] = "Event Successfully Deleted."

  redirect "/events"
end

#AJAX Calls

get "/events/all/:limit" do
  @events = @storage.all_events(@user_session.id, params[:limit])
  @status_for = "all"

  erb :_events_partial, :layout => false, :locals => { :events => @events, :status_for => @status_for }
end

get "/events/hosting/:limit" do
  @events = @storage.hosting_events(@user_session.id, params[:limit])
  @status_for = "hosting"

  erb :_events_partial, :layout => false, :locals => { :events => @events, :status_for => @status_for }
end

get "/events/attended/:limit" do
  @events = @storage.attended_events(@user_session.id, params[:limit])
  @status_for = "attended"

  erb :_events_partial, :layout => false, :locals => { :events => @events, :status_for => @status_for }
end

get "/events/upcoming/:limit" do
  @events = @storage.upcoming_events(@user_session.id, params[:limit])
  @status_for = "upcoming"

  erb :_events_partial, :layout => false, :locals => { :events => @events, :status_for => @status_for }
end

get "/e/:event_id/reload-participants" do    
  event_id = params[:event_id]
  participants = @storage.all_participants(event_id)
  current_status = @storage.get_attending_status(event_id, @user_session.id)

  puts "current status" + "#{current_status.nil?}"
  
  erb :_participants_partial, :layout => false, :locals => { :participants => participants, :current_status => current_status }
end

# support functions

def b2lah(user_id)
  pfp_decoded = Base64.decode64(@storage.get_pfp(user_id))

  pfp_file_name = "#{user_id}_pfp"
  pfp_file = Tempfile.new(pfp_file_name, '/tmp')
  pfp_file.binmode
  pfp_file.write pfp_decoded
  pfp_file.rewind

  content_type = `file --mime -b #{pfp_file.path}`.split(";")[0]
  extension = content_type.match(/gif|jpeg|jpg|png/).to_s
  pfp_file_name += ".#{extension}" if extension

  # pfp_file.close
  # pfp_file.unlink # delete temp file
  puts pfp_file.path
  pfp_file.path
  
end

def is_logged_in?
  @user_session.valid_token? == true
end

def event_exists?(event_id)
  p event_id
  valid_input = (event_id.to_i.to_s == event_id)
  if valid_input && !@storage.event_exists?(event_id)
    session[:error] = "This event with ID '#{event_id}' does not exist."
    redirect "/events"
  elsif !valid_input
    session[:error] = "Invalid event ID. Event ID's may only include numbers."
    redirect "/events"
  end
end

def authorized_to_edit?(event_id)
  owner = @storage.get_event_creator(event_id)
  if owner && (owner[:creator_id].to_i == @user_session.id.to_i)
    true
  else
    session[:error] = "You are not authorized to edit this event since you are not the owner."
    redirect "/e/#{event_id}"
  end
end

def redirect_to_login(error=nil)
  if error && is_logged_in? == false
    session[:error] = error
    redirect "/login"
  elsif is_logged_in? == false
    redirect "/login"
  end
end

def handle_image_file(params, username, event_id=nil)
  event_picture_filename = @storage.get_event_picture_filename(event_id)
  if params[:pfp]
    file = params[:pfp][:tempfile]
    image_name = "#{username}-pfp.png"
  elsif params[:'event-image'] && event_picture_filename
    file = params[:'event-image'][:tempfile]
    image_name = event_picture_filename
  elsif params[:'event-image']
    file = params[:'event-image'][:tempfile]
    image_name = "#{username}-e-#{SecureRandom.hex(3)}.png"
  elsif params[:'event-image'] == nil
    return nil
  end
  path = "/tmp/#{image_name}"
  puts "path = " + path

  File.open(path, 'wb') do |f|
    f.write(file.read)
  end

  return {image_name: image_name, path: path}
end

def event_validation(params)
  title = params[:title].strip
  description = params[:description].strip
  location = params[:location].strip
  date = params[:date].strip
  time_start = params[:'time-start'].strip
  time_end = params[:'time-end'].strip

  elements = [ {title: title},
               {description: description},
               {location: location},
               {date: date},
               {'starting-time': time_start},
               {'ending-time': time_end} ]
  elements.select! { |el| el.values[0] == '' }.map! { |el| el.keys[0].to_s }
  
  if elements.count == 1
    session[:error] = "You must fill out the #{elements[0]} section."
    halt erb :new_event
  elsif elements.count == 2
    elements[-1] = "and #{elements[-1]}"
    session[:error] = "You must fill out the #{elements.join(" ")} sections."
    halt erb :new_event
  elsif elements.count > 2
    elements[-1] = "and #{elements[-1]}"
    session[:error] = "You must fill out the #{elements.join(', ')} sections."
    halt erb :new_event
  end
end

helpers do
  def partial(template, locals = {})
    erb template, :layout => false, :locals => locals
  end
  
  def is_logged_in?
    @user_session.valid_token? == true
  end

  def event_owner?(event_id)
    owner = @storage.get_event_creator(event_id)
    if owner && (owner[:creator_id].to_i == @user_session.id.to_i)
      true
    else
      false
    end
  end

  def no_events_status(events_arr, status_for)
    if events_arr.empty?
      case status_for
        when "all" then "It's quite empty in here..."
        when "upcoming" then "You have no upcoming events."
        when "attended" then "You have not attended any events."
        when "hosting" then "You are not hosting any events."
      end
    end
  end

  # Splits the description based on newline string elements ~> Allows us to include <br> tags while also sanitizing the HTML
  def format_description(description) 
    description.split(/\R/).map(&:strip).reject { |str| str =~ /^$/ }
  end

  def format_date(date)
    d = Date.parse date
    d.strftime "%A, %b %d"
  end

  def format_time(date, time)
    t = format_datetime(date, time)
    t.strftime "%l:%M %p"
  end

  def format_datetime(date, time)
    # date = 2001-02-03
    date_arr = date.to_s.split('-')
    time_arr = time.to_s.split(':')

    Time.new(date_arr[0], date_arr[1], date_arr[2], time_arr[0], time_arr[1], time_arr[2])
  end
end