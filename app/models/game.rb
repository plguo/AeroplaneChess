class Game < ActiveRecord::Base
  has_many :players
  enum state: [:waiting, :playing, :finished]
  enum turn: [:blue, :yellow, :green, :red]
  after_create :set_players

  def ready?
    players.where(state: :ready).count == 4
  end

  def start!
    self[:turn] = rand(4)
    state = :playing
    save
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
