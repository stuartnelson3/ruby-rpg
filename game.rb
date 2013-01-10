require 'virtus'

module Die
  def roll
    (rand * 10).to_i
  end
end

module Mortality
  def alive?
    health > 0
  end
  def dead?
    !alive?
  end
end

module StandardAttack
  def damage_inflicted # pick random damage from range
    damage = attack.shuffle.first
    if (rand * 1000).to_i % 7 == 0
      damage * 1.5
    else
      damage
    end
  end
end

class Enemy
  include Virtus, Mortality, Die, StandardAttack

  attribute :name, String
  attribute :health, Fixnum
  attribute :defense, Fixnum
  attribute :attack, Array[Fixnum]
  attribute :hit_chance, Float, :default => 0.85
  attribute :experience, Fixnum # added to hero's experience when killed


  def choose_attack(enemy)
    if roll > 3
      strike(enemy)
    else
      cower
    end
  end

  def strike(enemy)
    if rand < hit_chance
      attack_damage = damage_inflicted
      enemy.health -= attack_damage
      puts "#{name} dealt #{attack_damage} to #{enemy.name}!"
      sleep 0.5
    else
      puts "#{name}'s attack missed!"
    end
  end
  def cower
    puts "#{name} cowers in fear!"
  end
end

class Hero
  include Virtus, Mortality, Die, StandardAttack

  attribute :name, String
  attribute :health, Fixnum
  attribute :defense, Fixnum
  attribute :attack, Array[Fixnum]
  attribute :hit_chance, Float, :default => 0.85
  attribute :experience, Fixnum, :default => 0
  attribute :next_level, Fixnum, :default => 10
  attribute :level, Fixnum, :default => 1

  attribute :in_battle, Boolean, :default => false
  attribute :current_enemies, Array[Enemy]

  def level_up
    next_level *= 1.5
    next_level = next_level.to_i
    level += 1
    puts "Reached level #{level}!"
  end

  def check_experience
    if experience > next_level
      level_up
    end
  end

  def idle
    if in_battle
      puts "In battle with #{current_enemies_names}"
      print "Attack with what?\n" # print out fighting methods. namespace in module?
      response = gets.strip
      if current_enemies.length > 1
        print "Attack which enemy?\n" # print out number of monsters
        index = gets.strip.to_i - 1
        strike(current_enemies[index])
      else
        strike(current_enemies.first)
      end
    else
      check_experience
      move
    end
  end

  def move
    print "What direction do you want to travel?\n"
    direction = gets.strip
    sleep 0.5
    puts "Moved #{direction}"
    if roll < 3
      print "You encountered an enemy! Fight it? y/n\n"
      sleep 0.5
      answer = gets.strip
      if answer.downcase == "y"
        enemy_count = (rand * 3).to_i + 1
        enemy_array = []
        enemy_count.times do
          enemy_array << Enemy.new(name: "Enemy", health: 20, defense: 100, attack: [3, 4, 5], experience: 5)
        end
        self.current_enemies = enemy_array
        self.in_battle = true
      else
        puts "Ran away!"
      end
    end
    idle
  end

  def current_enemies_names
    a = []
    current_enemies.each {|enemy| a << enemy.name }
    # a.last.insert(0, "and ")
    a.join(", ")
  end

  def strike(enemy) # hit % chance
    if rand < hit_chance
      attack_damage = damage_inflicted
      enemy.health -= attack_damage
      puts "#{name} dealt #{attack_damage} to #{enemy.name}!"
      sleep 0.5
    else
      puts "Your attack missed!"
    end
    if enemy.alive?
      enemy.choose_attack(self)
    else
      experience += enemy.experience
      current_enemies.delete(enemy)
      self.in_battle = false if current_enemies.empty?
      puts "You defeated #{enemy.name}!"
      sleep 0.5
    end
    idle
  end
end

module Bash # hero.extend(Bash) => use this to add new moves to characters
  def bash(enemy)
    enemy.health -= (damage_inflicted * 2)
  end
end

# class Enemies < Array
#   def <<(enemy)
#    if enemy.kind_of?(Hash)
#     super(Enemy.new(book))
#    else
#      super
#    end
#   end
# end

# require './game.rb'
# hero = Hero.new(name: "Hero", health: 100, defense: 100, attack: [5,6,7,8,9])
# enemy = Enemy.new(name: "Enemy", health: 10, defense: 100, attack: [5,6,7,8,9])
# hero.current_enemies = [enemy, enemy, enemy]
# hero2 = Hero.new(name: "other hero", health: 100, defense: 100, attack: 5)

puts "Greetings! Time to start a new adventure.\n"
print "What is your name?\n"
hero_name = gets.strip
sleep 0.5
puts "Hello, #{hero_name}! Prepare for an adventure!"
sleep 0.5
hero = Hero.new(name: "#{hero_name}", health: 100, defense: 100, attack: [5,6,7,8,9])
hero.idle