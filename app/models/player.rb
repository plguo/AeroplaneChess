class Player < ActiveRecord::Base
  require 'chess'

  belongs_to :game, touch: true
  enum color: [:blue, :yellow, :green, :red]
  enum state: [:waiting, :typing_name, :ready]

  serialize :chesses, ::ChessesGroup

  after_commit :delete_cache

  def move_chess!(chess_id, steps)
    if chess_id.between?(0,3)
      chess = self.chesses[chess_id]
      if chess.valid_move?(steps)
        path = chess.move_by!(steps)
        save
        return path.merge(start_count: chesses_count(chess_id))
      end
    end
  end

  def chesses_count(skip=nil)
    count = Hash.new(0)
    self.chesses.each do |chess|
      count[chess.position] += 1 unless chess.id == skip
    end
    {self[:color] => count.keep_if { |p,c| c > 1 }}
  end

  def movable_chesses(steps)
    list = self.chesses.map do |chess|
      chess.valid_move?(steps) ? chess.id : nil
    end
    list.compact
  end

  def collide_chesses!(positions)
    need_save = false
    list = self.chesses.map do |chess|
      if positions.include?(chess.position)
        need_save = true
        chess.back_to_airport!
        chess.to_id
      else
        nil
      end
    end
    self.save if need_save
    list.compact
  end

  def generate_chesses
    color_val = Player.colors[self.color]
    chesses_group = 4.times.map do |index|
      Chess.new(color_val ,index ,76 + 4 * color_val + index, false)
    end
    self.chesses = chesses_group
  end

  def finish?
    self.chesses.all? { |chess| chess.finished }
  end

  private
  def delete_cache
    Rails.cache.delete("Games/#{self.game_id}/players")
  end
end
