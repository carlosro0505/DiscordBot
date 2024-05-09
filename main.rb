require 'discordrb'
require 'open-uri'
require 'json'
require 'cgi'

#reading from file 'config.txt', making an array: each line in file (separated by \n)...
# ... has the token, app id, prefix (cmd word), and API key written respectively
config = File.foreach('config.txt').map { |line| line.strip }
token = config[0].to_s
client_id = config[1].to_s
prefix = config[2].to_s
api_key = config[3].to_s

bot = Discordrb::Commands::CommandBot.new token: token, client_id: client_id, prefix: prefix

#command to get current weather
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

#command to get air pollution
bot.command :pollution do |event, *args|
  city = args.join(' ')
  pollution_data = get_pollution(city, api_key)

  if pollution_data
    aqi = pollution_data['list'][0]['main']['aqi']
    event.respond "Air pollution in #{city}: AQI (Air Quality Index) is #{aqi}"
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
    event.respond "3-hour forecast for #{city}: #{temperature}°C, #{description.capitalize}"
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
  # Geocoding API call to get latitude and longitude
  geocoding_url = "http://api.openweathermap.org/geo/1.0/direct?q=#{CGI.escape(city)}&limit=1&appid=#{api_key}"
  geocoding_response = URI.open(geocoding_url).read
  geocoding_data = JSON.parse(geocoding_response)

  # Check for successful geocoding and extract coordinates
  if geocoding_data.any?
    lat = geocoding_data[0]['lat']
    lon = geocoding_data[0]['lon']
  else
    puts "Error: Could not find location for city: #{city}"
    return nil  # Handle error or provide a default response
  end

  # Construct pollution data URL with retrieved coordinates
  pollution_url = "http://api.openweathermap.org/data/2.5/air_pollution/forecast?lat=#{lat}&lon=#{lon}&appid=#{api_key}"

  puts "Fetching pollution data from: #{pollution_url}"
  begin
    response = URI.open(pollution_url).read
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

#send welcome message
bot.ready do
  bot.send_message(1236886018938896417, "Beep boop bop, friends! I am the Weather Wizz Bot. Some commands you can use are:

!weather City
!forecast City
!pollution City

These commands will show you the current weather conditions, forecasted weather conditions (in 3 hours), and air quality respectively in a city of your choosing.
")
end

at_exit { bot.stop }
bot.run
