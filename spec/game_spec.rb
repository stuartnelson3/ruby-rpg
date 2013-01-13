require 'spec_helper'

describe Hero do
  subject { Hero.new(name: "Hero", health: 100, defense: 100, attack: [5,6,7,8,9]) }

  it "should do [enter damage] without a weapon equipped" do
    subject.weapon.should be_nil
    subject.attack.should == [1, 2]
  end


  context "level_up" do
    it "should level up when experience > next_level"

    it "should raise attack modifier"
  
    it "should raise next_level"
  
    it "should raise defense"
  
    it "should raise health"
  end
  

end