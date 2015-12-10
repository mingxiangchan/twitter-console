require 'net/http'
require 'uri'
require 'base64'
require 'cgi'
require 'openssl'

require_relative 'secrets'

module TwitterOauth
  def params(consumer_key=CONSUMER_KEY)
    params = {
      'oauth_consumer_key' => consumer_key, 
      'oauth_nonce' => generate_nonce,
      'oauth_signature_method' => 'HMAC-SHA1',
      'oauth_timestamp' => Time.now.getutc.to_i.to_s, 
      'oauth_version' => '1.0'
    }
  end

  def get_request_token
    uri = "https://api.twitter.com/oauth/request_token"
    method = "POST"
    params = params()
    params['oauth_callback'] = "oob"
    signature_base_string = signature_base_string(method, uri, params)
    params['oauth_signature'] = url_encode(sign(CONSUMER_SECRET + '&', signature_base_string(method, uri, params)))

    #send request for request token to server
    token_data = parse_string(request_data(header(params), uri, method))

    @auth_token = token_data['oauth_token']
    @auth_token_secret = token_data['oauth_token_secret']

    return "https://twitter.com/oauth/authorize?oauth_token=#{@auth_token}&oauth_callback=oob"
  end

  def get_access_token(pin_code)
    uri = 'https://api.twitter.com/oauth/access_token'
    method = 'POST'
    params = params()
    params['oauth_verifier'] = pin_code
    params['oauth_token'] = @auth_token
    params['oauth_signature'] = url_encode(sign(CONSUMER_SECRET + '&' + @auth_token_secret, signature_base_string(method, uri, params)))

    #send request for access token to server
    data = parse_string(request_data(header(params), uri, method))
    byebug
  end

  def generate_nonce(size=7)
    Base64.encode64(OpenSSL::Random.random_bytes(size)).gsub(/\W/, '')
  end

  def signature_base_string(method, uri, params)
    encoded_params = params.sort.collect{ |k, v| url_encode("#{k}=#{v}") }.join('%26')
    method + '&' + url_encode(uri) + '&' + encoded_params
  end

  def url_encode(string)
    CGI::escape(string)
  end

  def sign(key, base_string)
    digest = OpenSSL::Digest.new('sha1')
    hmac = OpenSSL::HMAC.digest(digest, key, base_string)
    Base64.encode64(hmac).chomp.gsub(/\n/, '')
  end

  def header(params)
    header = "OAuth "
    params.each do |k, v|
      header += "#{k}=\"#{v}\", "
    end
    header.slice(0..-3)
  end

  def request_data(header, base_uri, method, post_data=nil)
    url = URI.parse(base_uri)
    http = Net::HTTP.new(url.host, 443)
    http.use_ssl = true

    if method == 'POST'
      resp, data = http.post(url.path, post_data, { 'Authorization' => header })
    else
      resp, data = http.get(url.to_s, { 'Authorization' => header })
    end
    resp.body
  end

  def parse_string(str)
    ret = {}
    str.split('&').each do |pair|
      key_and_val = pair.split('=')
      ret[key_and_val[0]] = key_and_val[1]
    end
    ret
  end
end