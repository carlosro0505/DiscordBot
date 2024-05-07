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

# Command to get air pollution
bot.command :pollution do |event, *args|
  city = args.join(' ')
  pollution_data = get_pollution(city, api_key)

  if pollution_data
    aqi = pollution_data['list'][0]['main']['aqi']
    event.respond "Air pollution in #{city}: AQI (Air Quality Index) - #{aqi}"
  else
    event.respond "Sorry, I couldn't find air pollution data for #{city}."
  end
end

bot.command :forecast do |event, *args|
  city = args.join(' ')
  forecast_data = get_forecast(city, api_key)

  if forecast_data
    forecast = forecast_data['list'][1]  # Access the second element (index 1) for next forecast
    temperature = forecast['main']['temp']
    description = forecast['weather'].first['description']
    event.respond "Weather forecast for #{city}: #{temperature}°C, #{description.capitalize}"
  else
    event.respond "Sorry, I couldn't find the weather forecast for #{city}."
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

def get_pollution(city, api_key)
  url = "http://api.openweathermap.org/data/2.5/air_pollution?q=#{CGI.escape(city)}&appid=#{api_key}"
  
  puts "Fetching pollution data from: #{url}"
  begin
    response = URI.open(url).read
    puts "Received response: #{response}"
    return JSON.parse(response)
  rescue OpenURI::HTTPError => e
    puts "Error fetching pollution data: #{e.message}"
    return nil
  end
end

def get_forecast(city, api_key)
  url = "http://api.openweathermap.org/data/2.5/forecast?q=#{CGI.escape(city)}&appid=#{api_key}&units=metric"
  
  begin
    response = URI.open(url).read
    return JSON.parse(response)
  rescue OpenURI::HTTPError => e
    puts "Error fetching forecast data: #{e.message}"
    return nil
  end
end

at_exit { bot.stop }
bot.run
