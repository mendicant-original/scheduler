class Scheduler
 
  class Expression
    
    # the Expression class provides a simple DSL
    # for creating Temporal expressions.  
    # runt comes with it's own, but I didn't care for it.

    DAYS = {
      :sunday    => Runt::Sunday,
      :monday    => Runt::Monday,
      :tuesday   => Runt::Tuesday,
      :wednesday => Runt::Wednesday,
      :thursday  => Runt::Thursday,
      :friday    => Runt::Friday,
      :saturday  => Runt::Saturday
    }

    WEEKDAYS = [Runt::Mon, Runt::Tue, Runt::Wed, Runt::Thu, Runt::Fri]

    def elems; @elems ||= []; end
    
    # returns a temporal expression for the given day
    # if :from and :to are given, it will be limited to that 
    # period of time
    def on(day, opts)
      exp = diweek(day)
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      elems << exp
      exp
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
      elems << exp
      exp
    end

    # similar to #every, but for multiple days
    # if :from and :to are given, all days will be limited to that 
    # period of time 
    def weekdays(opts)
      exp = WEEKDAYS.map{|i| Runt::DIWeek.new(i)}.inject{|m,e| m | e }
      exp = exp & reday(opts) if opts[:from] && opts[:to]
      elems << exp
      exp
    end

    
    # evaluate (join) expressions
    def join
      return nil unless elems && !elems.empty?
      elems[1..-1].inject(elems[0]) do |m, e|
        m = (m | e)
      end
    end
    
    
    ## helper methods to DRY up the code

    def diweek(sym)
      Runt::DIWeek.new(DAYS[sym])
    end

    def reday(opts)
      raise ArgumentError, "No :from or :to option passed" unless opts[:from] && opts[:to]
      args = opts[:from] + opts[:to]
      Runt::REDay.new(*args)
    end

  end

end