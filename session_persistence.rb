class SessionPersistence
  def initialize(user=nil)
    @username = user
    @creator_id = nil
    @login_time = 0
  end

  def sign_in(user, id)
    @username = user
    @creator_id = id
    @login_time = Time.now().to_i
  end

  def sign_out
    @username = nil
    @login_time = 0
    @creator_id = nil
  end

  def username
    @username
  end

  def id
    @creator_id
  end

  def valid_token?
    duration = (Time.now().to_i - @login_time)
    duration < 6000 # 100 mins
  end
end