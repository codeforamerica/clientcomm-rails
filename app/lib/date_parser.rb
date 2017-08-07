require 'timeliness'

class DateParser
  def self.parse(date, time)
    Timeliness.parse("#{date} #{time}", format: 'mm/dd/yyyy h:nn_ampm', zone: ENV['TIME_ZONE'])
  end
end
