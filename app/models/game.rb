class Game < ActiveRecord::Base
  has_many :players
  enum state: [:waiting, :roll, :rolling, :move, :moving, :finished]
  enum turn: [:blue, :yellow, :green, :red]
  after_create :set_players

  def ready?
    players.where(state: 2).count == 4
  end

  def start!
    self[:turn] = rand(4)
    self.state = :roll
    save
  end

  def next_state!(options={})
    state_sym = self.state.to_sym
    #Avoid unwanted multiple next_state! calls
    return if state_sym != options[:from]

    case self.state.to_sym
    when :roll
      self.state = :rolling
    when :rolling
      self.state = :move
      self.steps = rand(6) + 1
    when :move
      self.state = :moving
    end
    save
    self.state.to_sym
  end

  def move_chess!(chess)
    players[self[:turn]].move_chess(chess,self.steps)
  end

  private
  def set_players
    Player.colors.keys.each_with_index do |color, index|
      player = Player.new
      player.color = color
      player.game = self
      player.generate_chesses
      player.save
    end
  end
end
