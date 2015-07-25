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
    color = message[:color].to_i
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
    if @game.next_state! from: :roll, stage: message[:stage].to_i #roll -> rolling
      broadcast_info
    end
  end

  def roll_finished
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    if @game.next_state! from: :rolling, stage: message[:stage].to_i #rolling -> move
      broadcast_info(movables: @game.movable_chesses)
    end
  end

  def move
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    path = @game.move_chess!(message[:move].to_i)
    unless path.nil?
      if @game.next_state! from: :move, stage: message[:stage].to_i #move -> moving
        WebsocketRails["G#{@game.id}"].trigger(:move, path.merge(stage: @game.stage))
      end
    end
  end

  def move_finished
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    if @game.next_state! from: :moving, stage: message[:stage].to_i #moving -> roll
      broadcast_info(count: @game.chesses_count)
    end
  end

  def next
    game_id = message[:game_id].to_i
    @game = Game.find(game_id)
    if @game.next_state! from: :move, stage: message[:stage].to_i
      broadcast_info
    end
  end

  private

  def info
    players = @game.players.order(:color).each.map do |player|
      {
        :name => player.name,
        :state => player.state,
        :chesses => player.chesses.map{|c| c.to_info}
      }
    end
    {
      :state => @game.state,
      :stage => @game.stage,
      :turn => @game[:turn],
      :steps => @game.steps,
      :players => players
    }
  end

  def broadcast_info(options={})
    WebsocketRails["G#{@game.id}"].trigger(:update, info.merge(options))
  end
end
