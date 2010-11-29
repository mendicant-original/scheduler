require File.join(File.dirname(__FILE__),'spec_helper')

describe "Scheduler::Expression" do

  describe "multiple #on" do
  
    subject do
      Scheduler::Expression.new.instance_eval do
        on :monday, :from => [1,00], :to => [2,00]
        on :tuesday, :from => [2,00], :to => [3,00]
      end
    end
    
    let :comparator do
      Scheduler::Expression.new.instance_eval do
        on(:monday, :from => [1,00], :to => [2,00]) |
        on(:tuesday, :from => [2,00], :to => [3,00])
      end
    end
    
    let :times do
      [ Runt::PDate.min(2010,11,21),
        Runt::PDate.min(2010,11,22,0,59),
        Runt::PDate.min(2010,11,22,1,00),
        Runt::PDate.min(2010,11,22,1,01),
        Runt::PDate.min(2010,11,22,2,00),
        Runt::PDate.min(2010,11,22,2,01),
        Runt::PDate.min(2010,11,23,1,59),
        Runt::PDate.min(2010,11,23,2,00),
        Runt::PDate.min(2010,11,23,2,01),
        Runt::PDate.min(2010,11,23,3,00),
        Runt::PDate.min(2010,11,23,3,01),
        Runt::PDate.min(2010,11,24)
      ]
    end
    
    it "should act like set join" do
      
      times.each do |t|
        subject.include?(t).should equal comparator.include?(t)
      end
    end
    
  end
end