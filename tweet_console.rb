require 'bundler/setup'
Bundler.require

require_relative 'oauth_setup'

class TweetConsole
  include TwitterOauth
  def run!
    get_username
    if verify_user
      get_tweet
      post_tweet
    end
  end

  def get_username
    print "Enter your username: "
    @username = gets.chomp
  end

  def verify_user
    puts "Please visit the below URL to obtain a PIN from Twitter to post tweets from this app"
    authorization_url = get_request_token + "&screen_name=#{@username}"
    puts authorization_url
    print "Enter the PIN you receive here: "
    pin_code = gets.chomp
    verify_pin(pin_code)
  end

  def get_tweet
    put "Enter your tweet"
    @tweet_content = gets.chomp
  end

  def post_tweet
    if send_tweet(@tweet_content)
      puts "Success! Tweet sent!"
    else
      puts "Failure! Tweet not sent"
    end
  end
end

TweetConsole.new.run!