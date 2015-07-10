class Player < ActiveRecord::Base
  attr_reader :chesses
  belongs_to :game, touch: true
  enum color: [:blue, :yellow, :green, :red]
  enum state: [:waiting, :typing_name, :ready]
  serialize :chesses, ChessesGroup

  after_initialize :load_chesses

  def move(chess, steps)
    old_pos = self.raw_chesses[chess][0]
    case old_pos
    when old_pos

    end
  end
end
