class GamesSocketController < WebsocketRails::BaseController
  def new_game
    @game = Game.find_by(state: :waiting) || Game.create
    trigger_success info.merge(:game_id => @game.id)
  end

  def request_color
    game_id = message[:game_id]
    color = message[:color]
    if player = Player.find_by(game_id: game_id, color: color, state: :waiting)
      player.state = :typing_name
      player.save
      trigger_success player.id
      broadcast_info
    else
      trigger_failure 'taken'
    end
  end

  def set_name
    game_id = message[:game_id]
    @game = Game.find(game_id)
    id = message[:id].to_i
    if player = @game.players.find(id)
      name = message[:name].strip
      name = "Unnamed Player" if name.blank?
      player.name = ActionController::Base.helpers.sanitize(name)
      player.state = :ready
      player.save
    end

    if @game.ready?
      @game.start!
    end
    broadcast_info
  end

  private
  def info
    players = []
    @game.players.order(:color).each do |player|
      players << {:name => player.name, :state => player.state, :chesses => player.raw_chesses}
    end
    {:state => @game.state, :players => players}
  end

  def broadcast_info
    WebsocketRails["G#{@game.id}"].trigger(:update, info)
  end
end
