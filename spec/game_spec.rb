require 'spec_helper'

describe Hero do
  let (:hero) { Hero.new(name: "Hero", health: 100, defense: 100) }

  it "should do 1-2 damage without a weapon equipped" do
    hero.weapon.class.should == Fists
    hero.attack.should == [1, 2]
  end


  context "level_up" do
    before do
      hero.experience = 12
      hero.check_experience
    end

    it "should level up when experience > next_level" do
      hero.level.should == 2
    end

    it "should raise attack modifier" do
      hero.damage_modifier.should == 1.05
    end
  
    it "should raise next_level" do
      hero.next_level.should == 15
    end
  
    it "should raise defense" do
      hero.defense.should == 110
    end
  
    it "should raise health" do
      hero.health.should == 110
    end
  end
  

end