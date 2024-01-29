class SessionPersistence
  def initialize(user=nil)
    @username = user
    @creator_id = nil
    @login_time = 0
    @color = set_pfp_color
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

    # Randomize user color (aesthetic purposes only)
  def set_pfp_color
    chars = '0123456789ABCDEF'.split('')
    color = "#"

    6.times do
      color += chars.sample
    end
    color
  end
end