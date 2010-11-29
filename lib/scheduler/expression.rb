class Scheduler
 
  class Expression
    
    # the Expression class provides a simple DSL
    # for creating Temporal expressions.  
    # runt comes with it's own, but I didn't care for it.

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

    # returns a temporal expression for the given day
    # if :from and :to are given, it will be limited to that 
    # period of time
    def on(day, opts)
      exp = diweek(day)
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      @exp = @exp ? (@exp | exp) : exp
    end
      
    # similar to #on, but for multiple days
    # if :from and :to are given, all days will be limited to that 
    # period of time  
    def every(*args)
      first = diweek(args.shift)
      exp = args.inject(first) do |m,e|
        case e
        when Symbol
          m | diweek(e)
        when Hash
          m & reday(e)
        end
      end
      @exp = @exp ? (@exp | exp) : exp
    end

    # similar to #every, but for multiple days
    # if :from and :to are given, all days will be limited to that 
    # period of time 
    def weekdays(opts)
      exp = WEEKDAYS.map{|i| DIWeek.new(i)}.inject{|m,e| m | e }
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      @exp = @exp ? (@exp | exp) : exp
    end

    ## helper methods to DRY up the code

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