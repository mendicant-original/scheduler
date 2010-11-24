class Scheduler

  class Expression
    include Runt

    DAYS = {
      :sunday    => Sunday,
      :monday    => Monday,
      :tuesday   => Tuesday,
      :wednesday => Wednesday,
      :thursday  => Thursday,
      :friday    => Friday,
      :saturday  => Saturday
    }

    WEEKDAYS = [Mon, Tue, Wed, Thu, Fri]

    def on(day, opts)
      exp = diweek(day)
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      exp
    end
      
    def every(*args)
      first = diweek(args.shift)
      args.inject(first) do |m,e|
        case e
        when Symbol
          m | diweek(e)
        when Hash
          m & reday(e)
        end
      end
    end

    def weekdays(opts)
      exp = WEEKDAYS.map{|i| DIWeek.new(i)}.inject{|m,e| m | e }
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      exp
    end

    def diweek(sym)
      DIWeek.new(DAYS[sym])
    end

    def reday(opts)
      raise ArgumentError unless opts[:from] && opts[:to]
      fh, fm = opts[:from]
      th, tm = opts[:to]
      REDay.new(fh,fm,th,tm)
    end

  end

end