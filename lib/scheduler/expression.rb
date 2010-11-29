class Scheduler
 
  class Expression
    
    # the Expression class provides a simple DSL
    # for creating Temporal expressions.  
    # runt comes with it's own, but I didn't care for it.

    DAYS = {
      :Sunday    => Runt::Sunday,
      :Monday    => Runt::Monday,
      :Tuesday   => Runt::Tuesday,
      :Wednesday => Runt::Wednesday,
      :Thursday  => Runt::Thursday,
      :Friday    => Runt::Friday,
      :Saturday  => Runt::Saturday
    }

    WEEKDAYS = [Runt::Mon, Runt::Tue, Runt::Wed, Runt::Thu, Runt::Fri]

    # returns a temporal expression for the given day
    # if :from and :to are given, it will be limited to that 
    # period of time
    def on(day, opts)
      exp = diweek(day)
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      exp
    end
      
    # similar to #on, but for multiple days
    # if :from and :to are given, all days will be limited to that 
    # period of time  
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

    # similar to #every, but for multiple days
    # if :from and :to are given, all days will be limited to that 
    # period of time 
    def weekdays(opts)
      exp = WEEKDAYS.map{|i| Runt::DIWeek.new(i)}.inject{|m,e| m | e }
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      exp
    end

    ## helper methods to DRY up the code

    def diweek(sym)
      Runt::DIWeek.new(DAYS[sym])
    end

    def reday(opts)
      raise ArgumentError unless opts[:from] && opts[:to]
      args = opts[:from] + opts[:to]
      Runt::REDay.new(*args)
    end

  end

end