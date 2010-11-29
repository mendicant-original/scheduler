$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'runt'
require 'forwardable'
require 'scheduler/expression'

class Scheduler
  VERSION = '0.0.1'

  extend Forwardable
  include Runt
    
  def initialize(&block)
    @schedule = Schedule.new
    instance_eval(&block) if block_given?
  end

  # duration in minutes of the proposed meeting
  def duration(minutes)
    @duration = minutes
  end

  # adds a participant to the scheduler
  # must be used in block form
  # see scheduler_spec.rb for examples
  def participant(name, &block)
    event   = Event.new(name)
    exp     = Expression.new.instance_eval(&block)
    @schedule.add(event, exp)
  end

  def_delegator :@schedule, :events, :participants

  # will create an expression starting on the year month & day given
  # and lasting 7 days.
  def week_of(year,month,day)
    date  = PDate.new(DPrecision::Precision.day,year,month,day)
    @time_range = DateRange.new(date, date + 6)
  end

  # returns an array of arrays containing:
  #    time ranges (one for every 15 minutes of the week)
  #    attendees who could make it at that time
  def attendance
    results = Array.new
    each_increment do |dr|
      attendees = @schedule.select do |evt,expr| 
        expr.include?(dr.min) && expr.include?(dr.max)
      end
      results << [dr, attendees]
    end
    results
  end

  # compacts adjoining time ranges where the attendees are equal
  # to make the array easier to read
  def compacted_attendance
    results = Array.new
    attendance.inject do |(sd, su),(vd,vu)| 
      if su == vu
        [DateRange.new(sd.min, vd.max), vu]
      else
        results <<[sd,su]
        [vd,vu]
      end
    end
    results.reject{|d,u| u.empty?}
  end

  # places the time ranges with the most attendees at the top of the stack
  def best_attendance
    compacted_attendance.sort{|(d1, u1),(d2,u2)| u2.size <=> u1.size }
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
      t1 = PDate.new(DPrecision::Precision.min, 
                           t.year, t.mon, t.day, t.hour, t.min)
      t2 = t1 + @duration
      yield DateRange.new(t1, t2)
    end
  end

  def to_a
    best_attendance.map{|d,u| [range_string(d), u.map{|i| i.to_s}.sort] }
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

# extensions for loading from file

require 'fastercsv'
require 'yaml'
require 'scheduler/loadable'
require 'scheduler/helpers/date_and_time_helper'

class Scheduler

  extend Loadable
  include Helpers::DateAndTimeHelper

  load_lines_of_format :csv do |sched, row, opts|
    opts[:participant] ||= 0
    opts[:days] ||= 1
    opts[:from] ||= 2
    opts[:to] ||= 3
    FasterCSV.parse(row) do |r|
      unless r.field_row?
        sched.participant(r[opts[:participant]]) do
          days = (parse_days(r[opts[:days]]) || all_days)
          every( *(days << {
                      :from => parse_time(r[opts[:from]]),
                      :to => parse_time(r[opts[:to]])
                    }
                  ) 
               )
        end
      end
    end
    sched
  end

  load_files_of_format :yaml do |input, opts|
    yaml = YAML.load(input)
    raise ArgumentError unless yaml.is_a?(Hash)
    new do
      yaml.each do |partic, avails|
        raise ArgumentError unless avails.is_a?(Hash)
        opts[:zone] = avails.delete('zone') if avails['zone']
        args = []
        avails.each do |dexpr, texpr|
          days = parse_days(dexpr)
          fr, to = parse_time_range(texpr, opts[:zone])
          args << (days << { :from => fr, :to => to })
        end
        participant(partic) do
          args.each do |arg|
            every( *arg )
          end
        end
      end
    end
  end
  
end