class Player < ActiveRecord::Base
  attr_reader :chesses
  belongs_to :game, touch: true
  enum color: [:blue, :yellow, :green, :red]
  enum state: [:waiting, :typing_name, :ready]
  serialize :chesses, ChessesGroup

  after_initialize :load_chesses

  def move_chess!(chess_id, steps)
    if chess_id.between?(0,3)
      chess = self.chesses[chess_id]
      if chess.valid_move?(steps)
        path = chess.move_by!(steps)
        save
        return path
      end
    end
  end

  def generate_chesses
    self.chesses = 4.times.map do |index|
      Chess.new(@color ,index ,76 + 4 * @color + index, false)
    end
  end
end
