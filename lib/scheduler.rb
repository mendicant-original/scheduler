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

