
require 'time'

# Utility module for loading wday and time expressions from strings
# into format needed for Expression#every
#
module Helpers

  module DateAndTimeHelper
  
    VALID_DAY_EXPRESSIONS = {
      "su" => :sunday,
      "sun" => :sunday,
      "sunday" => :sunday,
      "m" => :monday,
      "mo" => :monday,
      "mon" => :monday,
      "monday" => :monday,
      "tu" => :tuesday,
      "tue" => :tuesday,
      "tues" => :tuesday,
      "tuesday" => :tuesday,
      "w" => :wednesday,
      "we" => :wednesday,
      "wed" => :wednesday,
      "wednesday" => :wednesday,
      "th" => :thursday,
      "thu" => :thursday,
      "thurs" => :thursday,
      "thursday" => :thursday,
      "f" => :friday,
      "fr" => :friday,
      "fri" => :friday,
      "friday" => :friday,
      "sa" => :saturday,
      "sat" => :saturday,
      "saturday" => :saturday
    }
    
    def all_days
      [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    end
    
    def parse_days(expr)
      return nil unless expr && !expr.empty?
      case expr
      when /\w+\s*-\s*\w+/
        #TODO: parse day range
      else
        expr.split(',').map {|d| parse_day(d)}
      end
    end
    
    def parse_day(expr)
      raise ArgumentError, "Unknown day '#{expr.strip}'" \
        unless day = VALID_DAY_EXPRESSIONS[expr.strip.downcase]
      day
    end
    
    def parse_time_range(expr, zone = nil)
      return nil unless expr && !expr.empty?
      expr.split(' - ').map {|t| parse_time(t.strip, zone)}[0..1]
    end
    
    # TODO: add zone to expr if no zone specified
    def parse_time(expr, zone = nil)
      return nil unless expr && !expr.empty?
      t = Time.parse(expr).getutc
      [t.hour, t.min]
    end
   
  end
  
end