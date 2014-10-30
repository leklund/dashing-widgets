require 'net/http'
require 'sun_times'
require 'time'
require 'date'

# Get a WOEID (Where On Earth ID)
# for your location from here:
# http://woeid.rosselliot.co.nz/
woe_id = 12765845
# lat lng fo sunrise sunset calc
lat = 38.945234
lng = -77.063612
# timezone to properyl display sunrise sunset
tz = "America/New_York"

# Temerature units:
# 'c' for Celcius
# 'f' for Fahrenheit
units = 'f'

sun_times = SunTimes.new

SCHEDULER.every '5m', :first_in => 0 do |job|
  http = Net::HTTP.new('query.yahooapis.com')

  response = http.request(Net::HTTP::Get.new("/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20%3D%20#{woe_id}%20and%20u%3D'#{units}'&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys'"))

  res = JSON.parse(response.body)

  forecast = res['query']['results']['channel']

  current_forecast = forecast['item']['condition']
  tomorrow = forecast['item']['forecast'][1]

  send_event('weather_plus', { :temp => "#{current_forecast['temp']}&deg;#{units.upcase}",
                          :condition => current_forecast['text'],
                          :title => "#{forecast['location']['city']}, #{forecast['location']['region']} Weather",
                          :tomorrow => "#{tomorrow['text']}. High #{tomorrow['high']}&deg;#{units.upcase}",
                          :moon_icon => get_mooncon(forecast),
                          :day_icon => get_daycon(forecast),
                          :sun_time => sunrise_or_set_text(forecast),
                          :wi_icon => wi_class(current_forecast['code'])})
end

# thanks ruby cookbook!
class Time
  def convert_zone(to_zone)
    original_zone = ENV["TZ"]
    utc_time = dup.gmtime
    ENV["TZ"] = to_zone
    to_zone_time = utc_time.localtime
    ENV["TZ"] = original_zone
    return to_zone_time
  end
end

def sunrise_or_set_text(forecast)
  sunrise = Time.parse(forecast["astronomy"]["sunrise"])
  sunset= Time.parse(forecast["astronomy"]["sunset"])

  if Time.now > sunrise && Time.now < sunset
    "Sunset @ #{sunset.strftime('%l:%M')}"
  elsif Time.now > sunset
    "Sunrise @ #{sunrise_tomorrow.strftime('%l%M')}"
  elsif Time.now < sunrise
    "Sunrise @ #{sunrise_today.strftime('%l:%M')}"
  end
end

def sunrise_today
  sun_times.rise(Date.today, lat, lng).convert_zone(tz)
end

def sunrise_tomorrow
  sun_times.rise(Date.today + 1, lat, lng).convert_zone(tz)
end

def sunset
  sun_time.set(Date.today, lat, lng).convert_zone(tz)
end

def sunrise
  sunrise_today
end

def get_daycon(forecast)
  sunrise = Time.parse(forecast["astronomy"]["sunrise"])
  sunset= Time.parse(forecast["astronomy"]["sunset"])

  after_sunrise = (Time.now - sunrise).to_i
  before_sunset = (sunset - Time.now).to_i
  if after_sunrise < 0 || before_sunset < 0
    'wi-stars'
  elsif after_sunrise.between?(0,1800) || before_sunset.between?(0,1800)
    'wi-horizon'
  elsif after_sunrise.between?(1800,3600) || before_sunset.between?(1800,3600)
    'wi-horizon-alt'
  else
    'wi-day-sunny'
  end
end

def get_mooncon(forecast)
  sunset= Time.parse(forecast["astronomy"]["sunset"])
  mooncons = %w(
    wi-moon-new
    wi-moon-young
    wi-moon-waxing-crescent
    wi-moon-waxing-quarter
    wi-moon-waxing-gibbous
    wi-moon-full
    wi-moon-waning-gibbous
    wi-moon-waning-quarter
    wi-moon-waning-crescent
    wi-moon-old
  )
  md = moon_day(sunset)
  case md
  when 1,29
    mooncons[0]
  else
    mooncons[(md + 1 ) / 3]
  end
end

def moon_day(t = Time.now)
  lp = 2551443;
  new_moon = Time.new(1970, 1, 7, 20, 35, 0)
  phase = (t.to_i - new_moon.to_i) % lp
  (phase.to_f / (24 * 3600)).floor + 1
end

def wi_class(code)
  case code.to_i
  when 0  #tornado
    'wi-tornado'
  when 1  #tropical storm
    'wi-hurricane'
  when 2  #hurricane
    'wi-hurricane'
  when 3  #severe thunderstorms
    'wi-lightning'
  when 4  #thunderstorms
    'wi-thunderstorm'
  when 5  #mixed rain and snow
    'wi-rain-mix'
  when 6  #mixed rain and sleet
    'wi-rain-mix'
  when 7  #mixed snow and sleet
    'wi-rain-mix'
  when 8  #freezing drizzle
    'wi-rain-mix'
  when 9  #drizzle
    'wi-showers'
  when 10  # freezing rain
    'wi-rain-mix'
  when 11  # showers
    'wi-rain'
  when 12  # showers
    'wi-rain'
  when 13  # snow flurries
    'wi-snow'
  when 14  # light snow showers
    'wi-snow'
  when 15  # blowing snow
    'wi-snow'
  when 16  # snow
    'wi-snowflake-cold'
  when 17  # hail
    'wi-hail'
  when 18  # sleet
    'wi-rain-mix'
  when 19  # dust
    'wi-dust'
  when 20  # foggy
    'wi-fog'
  when 21  # haze
    'wi-fog'
  when 22  # smoky
    'wi-smoke'
  when 23  # blustery
    'wi-cloudy-windy'
  when 24  # windy
    'wi-cloudy-gusts'
  when 25  # cold
    'wi-snowflake-cold'
  when 26  # cloudy
    'wi-cloudy'
  when 27  # mostly cloudy (night)
    'wi-night-cloudy'
  when 28  # mostly cloudy (day)
    'wi-day-sunny-overcast'
  when 29  # partly cloudy (night)
    'wi-night-partly-cloudy'
  when 30  # partly cloudy (day)
    'wi-day-cloudy'
  when 31  # clear (night)
    'wi-stars'
  when 32  # sunny
    'wi-day-sunny'
  when 33  # fair (night)
    'wi-night-clear'
  when 34  # fair (day)
    'wi-day-sunny'
  when 35  # mixed rain and hail
    'wi-storm-showers'
  when 36  # hot
    'wi-hot'
  when 37  # isolated thunderstorms
    'wi-lightning'
  when 38  # scattered thunderstorms
    'wi-lightning'
  when 39  # scattered thunderstorms
    'wi-lightning'
  when 40  # scattered showers
    'wi-showers'
  when 41  # heavy snow
    'wi-snowflake-cold'
  when 42  # scattered snow showers
    'wi-snow'
  when 43  # heavy snow
    'wi-snowflake-cold'
  when 44  # partly cloudy
    'wi-day-sunny-overcast'
  when 45  # thundershowers
    'wi-storm-showers'
  when 46  # snow showers
    'wi-snow'
  when 47  # isolated thundershowers
    'wi-storm-showers'
  end
end



