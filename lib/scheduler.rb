require 'runt'
require 'forwardable'
require 'scheduler/expression'

class Scheduler
  VERSION = '0.0.1'

  extend Forwardable
  include Runt

  attr_accessor :duration

  def initialize(&block)
    @schedule = Schedule.new
    instance_eval(&block)
  end

  def duration(d)
    @duration = d
  end

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

  # 
  def attendance
    results = Array.new
    each_increment do |dr|
      users = @schedule.select do |ev,xpr| 
        xpr.include?(dr.min) && xpr.include?(dr.max)
      end
      results << [dr, users]
    end
    results
  end

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
    results
  end

  def best_attendance
    compacted_attendance.reject{|d,u| u.empty?}.
      sort{|(d1, u1),(d2,u2)| u2.size <=> u1.size }
  end

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

  def utc_time(pdate)
    Time.utc(pdate.year,pdate.mon,pdate.day,pdate.hour,pdate.min)
  end

  def range_string(dr)
    max = dr.max.strftime("%H:%M")
    dr.min.strftime("%A %H:%M-#{max} %Z")
  end

  def to_a
    best_attendance.map{|d,u| [range_string(d), u.map{|i| i.to_s}.sort] }
  end

  def to_s
    to_a.map{|d,u| [d, u].flatten.join("\n  ") }.join("\n")
  end

end

