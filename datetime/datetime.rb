zones = [ {
    zone: 'America/New_York',
    label: 'DC'
  }, {
    zone: 'America/Los_Angeles',
    label: 'San Mateo'
  }, {
    zone: 'America/New_York',
    label: 'Syracuse'
  } ]

SCHEDULER.every '60s', first_in: 0 do
  times = zones.map do |zone| 
    { zone: zone[:label],
      time: TZInfo::Timezone.new(zone[:zone]).now().strftime('%l:%M')
    }
  end

  # use first time zone for date
  d = TZInfo::Timezone.new(zones.first[:zone]).now()

  send_event('datetime', {items: times, date: {day_of_week: d.strftime('%a'), day: d.day, month: d.strftime('%b')}})
end
