require 'discordrb'
require 'open-uri'
require 'json'
require 'cgi'

# Reading from file 'config.txt', making an array: each line in file (separated by \n)...
# ... has the token, app id, prefix (cmd word), and API key written respectively
config = File.foreach('config.txt').map { |line| line.strip }
token = config[0].to_s
client_id = config[1].to_s
prefix = config[2].to_s
api_key = config[3].to_s

bot = Discordrb::Commands::CommandBot.new token: token, client_id: client_id, prefix: prefix

# Command to get weather
bot.command :weather do |event, *args|
  city = args.join(' ')
  weather_data = get_weather(city, api_key)

  if weather_data
    temperature = weather_data['main']['temp']
    description = weather_data['weather'][0]['description']
    event.respond "Weather in #{city}: #{temperature}°C, #{description.capitalize}"
  else
    event.respond "Sorry, I couldn't find the weather for #{city}."
  end
end

def get_weather(city, api_key)
  url = "http://api.openweathermap.org/data/2.5/weather?q=#{CGI.escape(city)}&appid=#{api_key}&units=metric"
  
  begin
    response = URI.open(url).read
    return JSON.parse(response)
  rescue OpenURI::HTTPError => e
    puts "Error fetching weather data: #{e.message}"
    return nil
  end
end

at_exit { bot.stop }
bot.run
