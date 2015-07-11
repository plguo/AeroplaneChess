class GamesSocketController < WebsocketRails::BaseController
  def new_game
    #@game = Game.find_by(state: 0)
    @game = Game.last
    @game = Game.create if @game.nil?
    trigger_success info.merge(:game_id => @game.id)
  end

  def request_color
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    color = message[:color]
    player = Player.find_by(game_id: game_id, color: color, state: 0)
    unless player.nil?
      player.state = :typing_name
      player.save
      msg = {:id => player.id, :color => color}
      trigger_success msg
      broadcast_info
    else
      trigger_failure 'taken'
    end
  end

  def set_name
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    id = message[:id].to_i
    player = @game.players.find(id)
    unless player.nil?
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

  def roll
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    @game.next_state! from: :roll #roll -> rolling
    broadcast_info

    sleep 1.0

    @game.next_state! from: :rolling #rolling -> move
    broadcast_info
  end

  def move
    path = @game.move_chess!(message[:move].to_i)
    unless path.nil?
      @game.next_state! from: :move
      WebsocketRails["G#{@game.id}"].trigger(:move, path)
    end
  end

  private
  def info
    players = @game.players.order(:color).each.map do |player|
      {
        :name => player.name,
        :state => player.state,
        :chesses => player.chesses.map{|c| c.to_a}
      }
    end
    {:state => @game.state, :turn => @game[:turn], :steps => @game.steps, :players => players}
  end

  def broadcast_info
    WebsocketRails["G#{@game.id}"].trigger(:update, info)
  end
end
