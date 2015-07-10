class Game < ActiveRecord::Base
  has_many :players
  enum state: [:waiting, :roll, :rolling, :move, :moving, :finished]
  enum turn: [:blue, :yellow, :green, :red]
  after_create :set_players

  attr_reader :path

  def ready?
    players.where(state: 2).count == 4
  end

  def start!
    self[:turn] = rand(4)
    self.state = :roll
    save
  end

  def next_move!(options={})
    case self.state.to_sym
    when :roll
      self.state = :rolling
    when :rolling
      self.state = :move
      self.steps = rand(6) + 1
    when :move
      self.state = :moving
      self.path = pass
    end
    save
    self.state.to_sym
  end

  private
  def set_players
    Player.colors.keys.each_with_index do |color, index|
      player = Player.new
      player.color = color
      player.game = self
      player.raw_chesses = (0..3).to_a.map {|e| [76+index*4+e,false]}
      player.save
    end
  end
end
