require_relative 'secrets'

class TweetConsole
  def run!
    get_username
    if verify_user
      get_tweet
      post_tweet
    end
  end

  def get_username
    puts CONSUMER_KEY
  end

  def verify_user
  end

  def get_tweet
  end

  def post_tweet
  end
end

TweetConsole.new.run!