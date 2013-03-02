# jumping man demo
require 'chingu'
require 'gosu'

class Game < Chingu::Window
  include Gosu
  def initialize
    super(640, 480, false)

    @jm = JumpingMan.create(image: Image["jumping_man.png"])
    @jm.x = width / 2
    @jm.y = height - (@jm.height/2)
    @jm.dy, @jm.dx = 0, 0
    @jm.input = { :space => :jump,
                  :holding_left => :move_left,
                  :holding_right => :move_right }

    self.input = {[:q, :escape] => :exit}
  end

  def draw
    fill(Color::WHITE)
    self.caption = "JM dy: #{@jm.dy}; JM y: #{@jm.y}"
    super
  end
end

# Map class holds and draws tiles and gems.
class Map
  attr_reader :width, :height, :gems
  
  def initialize(window, filename)
    # Load 60x60 tiles, 5px overlap in all four directions.
    @tileset = Image.load_tiles(window, "media/CptnRuby Tileset.png", 60, 60, true)

    gem_img = Image.new(window, "media/CptnRuby Gem.png", false)
    @gems = []

    lines = File.readlines(filename).map { |line| line.chomp }
    @height = lines.size
    @width = lines[0].size
    @tiles = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
        when '"'
          Tiles::Grass
        when '#'
          Tiles::Earth
        when 'x'
          @gems.push(CollectibleGem.new(gem_img, x * 50 + 25, y * 50 + 25))
          nil
        else
          nil
        end
      end
    end
  end
  
  def draw
    # Very primitive drawing function:
    # Draws all the tiles, some off-screen, some on-screen.
    @height.times do |y|
      @width.times do |x|
        tile = @tiles[x][y]
        if tile
          # Draw the tile with an offset (tile images have some overlap)
          # Scrolling is implemented here just as in the game objects.
          @tileset[tile].draw(x * 50 - 5, y * 50 - 5, 0)
        end
      end
    end
    @gems.each { |c| c.draw }
  end
  
  # Solid at a given pixel position?
  def solid?(x, y)
    y < 0 || @tiles[x / 50][y / 50]
  end
end

class VelocityDecay
  class << self
    def g
      -9.8
    end

    def vertical(dy, dt)
      dy + g * dt
    end

    def horizontal(dx, modifier = 1)
      dx * (0.90 * modifier)
    end
  end
end

class JumpingMan < Chingu::GameObject
  attr_accessor :dy, :dx, :start_time

  def jump
    # self.y -= 50
    self.dy = 20
    @start_time = Time.now
  end

  def grounded?
    @y >= $window.height - height/2
  end

  def airbourne?
    !grounded?
  end

  def dt
    if @start_time
      Time.now - @start_time
    else
      0
    end
  end

  def move_left
    self.dx -= 4
  end

  def move_right
    self.dx += 4
  end

  def vert_decay
     self.dy = VelocityDecay.vertical(dy, dt)
  end

  def hori_decay
    modifier = airbourne? ? 1 : 0.5
    self.dx = VelocityDecay.horizontal(dx, modifier)
  end

  def update
    super

    vert_decay
    @y -= dy # d_vert_velocity
    hori_decay
    @x += dx # d_hori_velocity
    if grounded?
      # self.dy *= -1
      @y = ($window.height - height/2)
    end

    if !@x.between?(0, $window.width)
      self.dx *= -1
    end
  end
end

Game.new.show