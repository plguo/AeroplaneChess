class GamePrediction
  attr_accessor :turn
  def initialize(game)
    @chesses = game.chesses
    @turn = game[:turn]
  end

  def predict
    prediction = Hash.new(false)
    for i in 1..3
      player_id = (@turn + i) % 4
      for steps in 1..6
        @chesses[player_id].each do |chess|
          unless chess.in_airport?
            position = chess.position_after steps
            prediction[position] = true
          end
        end
      end

      if @chesses[player_id].any? { |chess| chess.in_airport?  }
        chess = Chess.on_runway_for_color(player_id)
        for steps in 1..6
          position = chess.position_after steps
          prediction[position] = true
        end
      end
    end
    prediction
  end

end
