require 'sinatra'
require 'redis'

# set :env, (ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development)
set :env, (ENV['RACK_ENV'] ? :production : :development)

configure :production do
  uri = URI.parse(ENV["REDISTOGO_URL"])
  redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

configure :development do
  redis = Redis.new
  puts "Interesting, the environment is development"
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
end


####
# ROUTES
####
get '/' do
  # if ENV['RACK_ENV']
  #   @env = ENV['RACK_ENV'].to_sym
  # end
  erb :index
end

post '/' do
  if params[:url] and not params[:url].empty?
    @shortcode = random_string(5)
    redis.setnx("links:#{@shortcode}", params[:url]) # .setnx = Set if n exists
    
    #The ‘links:’ part of the key isn’t strictly required, but it’s good practice 
    #to split your Redis keys into namespaces so if you decide later on to store 
    #more information in the same database,
  end
  erb :index
end

get '/:shortcode' do
  @url = redis.get("links:#{params[:shortcode]}")
  redirect @url || '/'
end
