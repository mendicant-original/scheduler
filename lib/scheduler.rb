require 'rubygems'
require 'runt'
require 'forwardable'
require 'scheduler/helpers/date_and_time_helper'
require 'scheduler/expression'

class Scheduler
  VERSION = '0.0.1'

  extend Forwardable
    
  def initialize(&block)
    @schedule = Runt::Schedule.new
    if block_given?
      block.arity == 1 ? block[self] : instance_eval(&block) 
    end
  end

  # duration in minutes of the proposed meeting
  def duration(minutes)
    @duration = minutes
  end

  # adds a participant to the scheduler
  # must be used in block form
  # see scheduler_spec.rb for examples
  def participant(name, &block)
    event          = Runt::Event.new(name)
    expression     = Expression.new
    block.arity == 1 ? block[expression] : expression.instance_eval(&block)
    @schedule.add(event, expression.join)
  end

  def_delegator :@schedule, :events, :participants

  # will create an expression starting on the year month & day given
  # and lasting 7 days.
  def week_of(year,month,day)
    date  = Runt::PDate.day(year,month,day)
    @time_range = Runt::DateRange.new(date, date + 6)
  end

  # returns an array of arrays containing:
  #    time ranges (one for every 15 minutes of the week)
  #    attendees who could make it at that time
  def attendance
    results = Array.new
    each_increment do |date_range|
      attendees = @schedule.select do |event,availability| 
        availability.include?(date_range.min) && 
        availability.include?(date_range.max)
      end
      results << [date_range, attendees]
    end
    results
  end

  # compacts adjoining time ranges where the attendees are equal
  # to make the array easier to read
  def compacted_attendance
    results = Array.new
    attendance.inject do |(m_dr, m_p),(o_dr,o_p)| 
      if m_p == o_p
        [Runt::DateRange.new(m_dr.min, o_dr.max), o_p]
      else
        results <<[m_dr,m_p]
        [o_dr,o_p]
      end
    end
    results.reject{|_,participants| participants.empty?}
  end

  # places the time ranges with the most attendees at the top of the stack
  def best_attendance
    compacted_attendance.sort{|(dr_a, p_a),(dr_b,p_b)| p_b.size <=> p_a.size }
  end

  # iterates over the time_range 
  # yielding a DateRange that is @duration in length 
  #
  # this doesn't seem right to me
  # there has to be a better way to do this
  def each_increment(minutes=15)
    min = utc_time(@time_range.min)
    max = utc_time(@time_range.max)

    (min..max).step(minutes * 60) do |t|
      start = Runt::PDate.min(t.year, t.mon, t.day, t.hour, t.min)
      stop = start + @duration
      yield Runt::DateRange.new(start, stop)
    end
  end

  def to_a
    best_attendance.map{|dr,p| [range_string(dr), p.map{|i| i.to_s}.sort] }
  end

  def to_s
    to_a.map{|d,u| [d, u].flatten.join("\n  ") }.join("\n")
  end

  ## helper methods

  def utc_time(pdate)
    Time.utc(pdate.year,pdate.mon,pdate.day,pdate.hour,pdate.min)
  end

  def range_string(dr)
    max = dr.max.strftime("%H:%M")
    dr.min.strftime("%A %H:%M-#{max} %Z")
  end

end




# Extensions for loading from file
# Possibly for clarity this should be moved to a different source file
# See README for example of YAML file format implemented below
#
require 'yaml'
require 'scheduler/loadable'
require 'scheduler/helpers/date_and_time_helper'

class Scheduler

  extend Loadable
  include Helpers::DateAndTimeHelper

  
  load_files_of_format :yaml do |input, opts|
    yaml = YAML.load(input)
    raise ArgumentError unless yaml.is_a?(Hash)
    new do
      yaml.each do |partic, avails|
        raise ArgumentError unless avails.is_a?(Hash)
        opts[:zone] = avails.delete('zone') if avails['zone']
        participant(partic) do |p|
          avails.each do |dexpr, texpr|
            days = parse_days(dexpr)
            fr, to = parse_time_range(texpr, opts[:zone])
            if fr && to
              p.every( *(days << { :from => fr, :to => to }) )
            else
              p.every( *(days) )
            end
          end
        end
      end
    end
  end
  
end