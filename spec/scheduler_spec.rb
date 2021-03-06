
describe "Scheduler" do

  before do
    @sched = Scheduler.new
  end

  describe "week_of" do
    it "should add a week range" do
      week = @sched.week_of(2010,11,21)
      week.should include Date.new(2010,11,21)
      week.should include Date.new(2010,11,27)
      week.should_not include Date.new(2010,11,20)
      week.should_not include Date.new(2010,11,28)
    end
  end

  describe "participant" do
    it "should add a participant" do
      @sched.participant("Gregory Brown") do
        on(:monday, :from => [15,00], :to => [19,00])
        on(:tuesday, :from => [20,00], :to => [23,00])
        on(:thursday, :from => [15,00], :to => [19,00])
      end
      time = Runt::PDate.min(2010,11,23,20,15)
      @sched.participants(time).first.to_s.should == "Gregory Brown"
    end
  end

  describe "to_a" do

    it "should be an array of all start times that have valid participants" do

      schedule = Scheduler.new do 

        week_of 2010,11,21
        
        duration 90

        participant('Gregory Brown') do
          on(:monday,   :from => [14,00], :to => [19,00] ) |
          on(:tuesday,  :from => [20,00], :to => [23,00] ) |
          on(:thursday, :from => [15,00], :to => [19,00] )
        end

        participant('Jordan Byron') do 
          on(:monday,    :from => [15,00], :to => [18,00] ) |
          on(:wednesday, :from => [20,00], :to => [23,00] ) |
          on(:thursday,  :from => [15,00], :to => [18,30] )
        end
      
        participant('Hoban Washburne') do
          on(:monday,    :from => [15,00], :to => [18,00] ) |
          on(:wednesday, :from => [20,00], :to => [23,00] ) |
          on(:thursday,  :from => [15,00], :to => [18,30] )
        end

        participant('Malcolm Reynolds') do
          on(:monday,    :from => [15,00], :to => [18,00] ) |
          on(:wednesday, :from => [20,00], :to => [23,00] ) |
          on(:friday,    :from => [16,00], :to => [19,00] )
        end

        participant('Jayne Cobb') do
          weekdays(:from => [15,00], :to => [18,00] )
        end

        participant('Zoe Washburne') do
          every(:monday, :tuesday, :thursday, :from => [15,00], :to => [18,00] )
        end

        participant('Inara Serra') do
          every(:monday, :tuesday, :thursday )
        end
         
      end

      a = schedule.to_a
      a.should be_an Array
      a.first.last.size.should == 7
      
      first = ["Monday 15:00-18:00 +00:00", 
        ["Gregory Brown", 
         "Hoban Washburne",
         "Inara Serra",
         "Jayne Cobb", 
         "Jordan Byron", 
         "Malcolm Reynolds",
         "Zoe Washburne"]
      ]
      a.first.should == first
    end

  end

  
end
