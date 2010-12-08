
FIXTURES_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

module LoadHelper
  
  def load_yaml_file(file)
    schedule = Scheduler.load_from( File.join(FIXTURES_PATH, file), :yaml )
    schedule.week_of 2010,11,21
    schedule.duration 90
    schedule
  end
  
end


describe 'load from yaml file with no timezones specified' do

  include LoadHelper
  
  let(:input_file) { 'no_zones.yaml' }
  let :expected do
    ["Monday 15:00-18:00 +00:00", 
      ["Gregory Brown", 
       "Hoban Washburne",
       "Inara Serra",
       "Jayne Cobb", 
       "Jordan Byron", 
       "Malcolm Reynolds",
       "Zoe Washburne"]
    ]  
  end

  it 'output array should match expected' do
    schedule = load_yaml_file(input_file)
    schedule.to_a.first.should eql(expected)
  end
    
end

describe 'load from yaml file with timezones specified per participant' do

  include LoadHelper
  
  let(:input_file) { 'zones.yaml' }
  let :expected do
    ["Monday 15:00-18:00 +00:00", 
      ["Gregory Brown", 
       "Hoban Washburne",
       "Inara Serra",
       "Jayne Cobb", 
       "Jordan Byron", 
       "Malcolm Reynolds",
       "Zoe Washburne"]
    ]  
  end
  
  it 'output array should match expected' do
    schedule = load_yaml_file(input_file)
    schedule.to_a.first.should eql(expected)
  end

end


describe 'load from yaml file with timezones specified per time' do

  include LoadHelper

  let(:input_file) { 'indiv_zones.yaml' }
  let :expected do
    ["Monday 15:00-18:00 +00:00", 
      ["Gregory Brown", 
       "Hoban Washburne",
       "Inara Serra",
       "Jayne Cobb", 
       "Jordan Byron", 
       "Malcolm Reynolds",
       "Zoe Washburne"]
    ]  
  end
  
  it 'output array should match expected' do
    schedule = load_yaml_file(input_file)
    schedule.to_a.first.should eql(expected)
  end
  
end