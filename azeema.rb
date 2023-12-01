require "sinatra"
require "sinatra/content_for"
require "tilt/erubis"
require 'date'

require_relative "database_persistence.rb"
require_relative "session_persistence.rb"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
  also_reload "session_persistence.rb"
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
end

get "/" do
  erb :home, layout: :layout
end

# Load user signup page
get "/users/new-user" do

  erb :new_user
end

# Create new user
post "/users/new-user" do
  @storage.create_new_user(params[:name], params[:username], params[:password])
  redirect "/login"
end

# Load Login Page
get "/login" do
  p @user_session.valid_token?
  erb :login
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

get "/events/create-event" do
  if !is_logged_in?
    session[:error] = "Must be logged in to create an event."
    redirect "/login"
  else
    erb :new_event
  end
end

post "/events/create-event" do
  @storage.create_new_event(params[:title], params[:description], params[:location], params[:date], params[:time], @user_session.id)
end

get "/users/:username/events" do
  @username = params[:username]
  @all_events = @storage.all_user_events(@username)
  erb :user_events
end

get "/users/:username/events/:event_id" do
  event_id = params[:event_id]
  @event = @storage.single_event(event_id)
  p @event

  erb :event
end

# support functions

def is_logged_in?
  @user_session.valid_token? == true
end

helpers do
  def is_logged_in?
    @user_session.valid_token? == true
  end
end