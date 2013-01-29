require 'virtus'
require 'rspec'

module Die
  def roll
    (rand * 10).to_i
  end
  # s is the number of sides
  # Die.dice(s).take(n) => n dice with s sides
  # Die.dice(6).take(2) => [3, 6]
  def self.dice(s)
    Enumerator.new do |e|
      loop do 
        e.yield Random.rand(s) + 1
      end
    end
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

module LevelUp
  def check_experience
    if experience > next_level
      level_up
    end
  end

  def level_up
    self.next_level *= 1.5
    self.next_level = next_level.to_i
    self.level += 1
    level_up_attack
    level_up_health
    level_up_defense
    puts "Level up! You're now level #{level}!"
  end

  def level_up_attack
    self.damage_modifier += 0.05
  end

  def level_up_health
    self.health = (health * 1.1).to_i
  end

  def level_up_defense
    self.defense = (defense * 1.1).to_i
  end
end

module StandardAttack
  def damage_inflicted
    damage = attack.shuffle.first
    if (rand * 1000).to_i % 7 == 0
      (damage * 1.5).to_i
    else
      damage
    end
  end
end

class Weapon
  include Virtus
  def attack_damage(modifier)
    Range.new(
      *attack.split('-').values_at(0, -1).map {|lim| lim.to_i * modifier }.map(&:to_i)
    ).to_a
  end
end
class Sword < Weapon
  attribute :attack, String, :default => "5-7"
end
class Fists < Weapon
  attribute :attack, String, :default => "1-2"
end

class BaseClass
  include Virtus

  attribute :name, String
  attribute :health, Fixnum
  attribute :defense, Fixnum
  attribute :hit_chance, Float, :default => 0.85
  attribute :damage_modifier, Float, :default => 1.0
  attribute :experience, Fixnum, :default => 0
  attribute :weapon, Weapon, :default => Fists.new

  # work on having the level difference between the two enemies
  # figure into damage reduction, hit chance, et c.
  attribute :level, Fixnum, :default => 1

  def attack
    weapon.attack_damage(damage_modifier)
  end

  def physical_damage_reduction
    # level_modifier = 100 * (level - 1)
    1 - (defense.to_f - 1000)
  end
end

class Enemy < BaseClass
  include Virtus, Mortality, Die, StandardAttack

  # Enemy.instance_methods(false) gives instance methods
  # unique to the class. Randomly have one of these be 
  # selected in the choose_attack method?
  def fight_methods
    self.class.instance_methods(false).
      reject{|a| a == :choose_attack || a == :fight_methods }
  end

  def choose_attack(enemy)
    # picks random attack from array of methods available
    # re-work to rand 1000 and weight certain attacks?
    send(fight_methods.shuffle.first, enemy)
  end

  def strike(enemy)
    if rand < hit_chance
      attack_damage = damage_inflicted * enemy.physical_damage_reduction
      enemy.health -= attack_damage.to_i
      puts "#{name} dealt #{attack_damage} to #{enemy.name}!"
      sleep 0.5
    else
      puts "#{name}'s attack missed!"
    end
  end

  def cower(*_)
    puts "#{name} cowers in fear!"
  end
end

class String
  def constantize
    self.split("::").inject(Module) {|acc, val| acc.const_get(val) }
  end
end

module CharacterAttackProgression

  def add_new_attacks
    add_bash if level > 3
    add_so_and_so if level > 5
    add_so_and_so if level > 8
    add_so_and_so if level > 10
    add_so_and_so if level > 12
  end

  ############
  #
  # add attack modules to hero, e.g.
  #
  # add_bash
  #
  # add_slice
  #
  ############

  def method_missing(method_name, *args)
    if method_name.to_s.start_with?('add_')
      extend method_name.slice(4..-1).camelize.constantize
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.start_with?('add_') || super
  end
end

class Hero < BaseClass
  include Virtus, Mortality, Die, StandardAttack, LevelUp, CharacterAttackProgression

  attribute :next_level, Fixnum, :default => 10

  attribute :in_battle, Boolean, :default => false
  attribute :current_enemies, Array[Enemy]


  # find modules included in class
  # can use this to find available moves
  # for the random select on enemy attack back
  def self.mixin_ancestors(include_ancestors=true)
    ancestors.take_while {|a| include_ancestors || a != superclass }.
    select {|ancestor| ancestor.instance_of?(Module) }
  end

  def idle
    if in_battle?
      puts "In battle with #{current_enemies_names}"
      print "Attack with what?\n" # print out fighting methods. namespace in module? list of attack methods on included modules?
      # namespace all attacks in an Attack module, then have separate modules for the different attacks
      # that way you can just target the namespace Attacks with the mixin_ancestors method
      # and list the available attacks that way
      # follow this pattern with Magic and other fight moves?

      # find some way to get current list of methods for attack/defend
      # including the extended videos
      # list methods Hero.instance_methods.reject{ self.methods }
      # self.methods.reject { Hero.instance_methods }
      # try using bitwise operators, &, |
      # the methods that were added after the creation of the 
      # class (the added attacks)
      #
      # should return the methods that have been added
      # added_methods = hero.methods - hero.class.instance_methods

      # then find the unique methods available to hero
      # added_methods | self.class.instance_methods(false).
      #   reject{|a| a == :undesired_methods }

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
      add_new_attacks
      move
    end
  end

  def move
    print "What direction do you want to travel?\n"
    direction = gets.strip
    sleep 0.5
    puts "Moved #{direction}"
    if roll < 3
      print "You were attacked! Fight? y/n\n"
      sleep 0.5
      answer = gets.strip
      if answer.downcase == "y"
        enemy_count = (rand * 3).to_i + 1
        enemy_array = []
        enemy_count.times do
          enemy_array << Enemy.new(name: "Enemy", health: 20, defense: 100, experience: 15)
        end # refactor into create_enemy_array method
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
    a.last.insert(0, "and ") if a.length > 1
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
      self.experience += enemy.experience
      puts "Gained #{enemy.experience} experience!"
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
#     super(Enemy.new(enemy))
#    else
#      super
#    end
#   end
# end

# require './game.rb'
# hero = Hero.new(name: "Hero", health: 100, defense: 100, weapon: Sword.new)
# enemy = Enemy.new(name: "Enemy", health: 10, defense: 100, weapon: Fists.new)
# hero.current_enemies = [enemy, enemy, enemy]
# hero2 = Hero.new(name: "other hero", health: 100, defense: 100, attack: 5)

# puts "Greetings! Time to start a new adventure.\n"
# print "What is your name?\n"
# hero_name = gets.strip
# sleep 0.5
# puts "Hello, #{hero_name}! Prepare for an adventure!"
# sleep 0.5
# hero = Hero.new(name: "Hero", health: 100, defense: 100, weapon: Sword.new)
# hero.idle