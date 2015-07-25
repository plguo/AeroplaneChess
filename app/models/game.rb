class Game < ActiveRecord::Base
  has_many :players, dependent: :destroy
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
    return false unless self.stage == options[:stage] && state_sym == options[:from]

    case state_sym
    when :roll
      self.state = :rolling
    when :rolling
      self.state = :move
      self.steps = rand(3) + 4
    when :move
      unless movable_chesses.empty?
        self.state = :moving
      else
        self[:turn] = (self[:turn] + 1) % 4
        self.state = :roll
      end
    when :moving
      if self.players[self[:turn]].finish?
        self.state = :finished
      else
        self.state = :roll
        unless self.steps == 6
          self[:turn] = (self[:turn] + 1) % 4
        end
      end
    end
    self.stage += 1
    save
  end

  def move_chess!(chess)
    path = self.players[self[:turn]].move_chess!(chess,self.steps)
    unless path.nil?
      check_positions = [path[:path][-1], path[:flyby]].compact
      collided = []
      self.players.each_with_index do |player, index|
        collided += player.collide_chesses!(check_positions) unless index == self[:turn]
      end
      path.merge(collided: collided, count: chesses_count)
    end
  end

  def movable_chesses
    self.players[self[:turn]].movable_chesses(self.steps)
  end

  def chesses_count
    count_data = Hash.new
    self.players.each do |player|
      count_data.merge! player.chesses_count
    end
    count_data
  end

  def chesses
    self.players.to_a.map do |player|
      player.chesses
    end
  end
  private

  def cached_players
    Rails.cache.fetch("Games/#{self.id}/players") do
      self.players.to_a
    end
  end

  def set_players
    Player.colors.keys.each_with_index do |color, index|
      player = Player.new
      player.color = color
      player.game_id = self.id
      player.generate_chesses
      player.save
    end
  end
end
