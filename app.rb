require 'sinatra'
require 'redis'
require 'json'

set :env, (ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development)
#set :env, (ENV['RACK_ENV'] ? :production : :development)

configure :development do
  ENV["REDISTOGO_URL"] = 'redis://localhost:6379' 
  #redis = Redis.new
  puts "Interesting, the environment is development"
end

configure do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  puts "Host = #{uri.host}, Port = #{uri.port}, Password = #{uri.password}"
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password) #REDIS is in all caps so its treated as a fixed variable
end


####
# HELPER METHODS
####
helpers do
  include Rack::Utils
  alias_method :h, :escape_html #this aliases the letter h to the Rack's escape_html method

  def random_string(length)
    rand(36**length).to_s(36)
  end
  
  def clean_url(url)
    #.gsub(/http[s]?:\/\//,"")
    (url.include?("http://") || url.include?("http://")) ? url : "http://" + url
  end
end


####
# ROUTES
####
get '/' do
  # content_type :json if this was supposed to render json
  erb :index
end

post '/' do
  if params[:url] and not params[:url].empty?
    @shortcode = random_string(5)
    REDIS.setnx("links:#{@shortcode}", params[:url]) # .setnx = Set if n exists
    REDIS.setnx("links:#{@shortcode}:clicks", 0)
    
    #The ‘links:’ part of the key isn’t strictly required, but it’s good practice 
    #to split your Redis keys into namespaces so if you decide later on to store 
    #more information in the same database,
  end
  #erb :index
  { :url => "http://ten.io/#{@shortcode}", :shortcode => @shortcode }.to_json
end

get '/stats' do
    @end_url = REDIS.get("links:#{params[:shortcode]}")
    @clicks = REDIS.get("links:#{params[:shortcode]}:clicks")
    { :end_url => @end_url, :clicks => @clicks }.to_json
end

get '/:shortcode' do
  if params[:shortcode] != "favicon.ico"
    puts "SHORTCODE = #{params[:shortcode]}"
    @url = clean_url(REDIS.get("links:#{params[:shortcode]}"))
    REDIS.incr("links:#{params[:shortcode]}:clicks")
  end
  
  redirect @url || '/'
end
