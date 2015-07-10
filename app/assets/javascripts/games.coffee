# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
positions = [[196.8,559.2],[180.0,522.0],[180.0,486.0],[196.8,448.8],[163.2,415.2],[126.0,432.0],[90.0,432.0],[52.8,415.2],[36.0,378.0],[36.0,342.0],[36.0,306.0],[36.0,270.0],[36.0,234.0],[52.8,196.8],[90.0,180.0],[126.0,180.0],[163.2,196.8],[196.8,163.2],[180.0,126.0],[180.0,90.0],[196.8,52.8],[234.0,36.0],[270.0,36.0],[306.0,36.0],[342.0,36.0],[378.0,36.0],[415.2,52.8],[432.0,90.0],[432.0,126.0],[415.2,163.2],[448.8,196.8],[486.0,180.0],[522.0,180.0],[559.2,196.8],[576.0,234.0],[576.0,270.0],[576.0,306.0],[576.0,342.0],[576.0,378.0],[559.2,415.2],[522.0,432.0],[486.0,432.0],[448.8,415.2],[415.2,448.8],[432.0,486.0],[432.0,522.0],[415.2,559.2],[378.0,576.0],[342.0,576.0],[306.0,576.0],[270.0,576.0],[234.0,576.0],[306.0,520.8],[306.0,484.8],[306.0,448.8],[306.0,412.8],[306.0,376.8],[306.0,340.8],[91.2,306.0],[127.2,306.0],[163.2,306.0],[199.2,306.0],[235.2,306.0],[271.2,306.0],[306.0,91.2],[306.0,127.2],[306.0,163.2],[306.0,199.2],[306.0,235.2],[306.0,271.2],[520.8,306.0],[484.8,306.0],[448.8,306.0],[412.8,306.0],[376.8,306.0],[340.8,306.0],[40.8,571.2],[40.8,508.8],[103.2,508.8],[103.2,571.2],[40.8,103.2],[40.8,40.8],[103.2,40.8],[103.2,103.2],[508.8,103.2],[508.8,40.8],[571.2,40.8],[571.2,103.2],[508.8,571.2],[508.8,508.8],[571.2,508.8],[571.2,571.2],[163.2,592.8],[19.2,163.2],[448.8,19.2],[592.8,448.8]]

log = (obj) ->
  console.log(obj)

class Game
  constructor: ->
    @player = {id: -1, color: -1}
    @move_lock = false

  set_channel: (channel_name) ->
    $t = @
    @channel = @dispatcher.subscribe(channel_name)
    @channel.bind 'update', (message) ->
      $t.state = message.state
      $t.turn = message.turn
      $t.steps = message.steps
      $t.path = message.path
      $t.players = message.players

      $t.update()
      return
    return

  connect: (url) ->
    $t = @
    @dispatcher = new WebSocketRails(url)

    @dispatcher.bind 'log', (msg) ->
      log(msg)

    @dispatcher.trigger 'game.new', {}
    , (message) ->
      $t.game_id = message.game_id
      $t.state = message.state
      $t.turn = message.turn
      $t.steps = message.steps
      $t.path = message.path
      $t.players = message.players
      $t.update()
      $t.set_channel('G'+$t.game_id)
      return
    , (message) ->
      return

    return

  update: ->
    console.log(@)
    self = @
    player_data = ['','','','']

    for color, player of @players
      if player.state == "waiting" && self.player.color == -1
        player_data[color] = 'choosing'
      else if player.state == "typing_name"
        player_data[color] = 'typing' if color != self.player.color
      else if player.state == "ready" && @state == "waiting"
        player_data[color] = 'ready'
      else
        player_data[color] = 'none'

      $('#p'+color+' .name-display').first().text(player.name) if player.name != null

    if @state == 'roll'
      if @turn == @player.color
        player_data[@turn] = 'roll'
      else
        player_data[@turn] = 'waiting'
    else if @state == 'rolling'
      player_data[@turn] = 'rolling'
    else if @state == 'move' || @state == 'moving'
      player_data[@turn] = 'move'
      $('#p'+@turn+' .dice').first().attr('data-face', @steps)

    for color, state of player_data
      $('#p'+color).attr('data-state',state) unless state == ''

    return

  request_color: (color) ->
    $t = @
    @dispatcher.trigger 'game.request_color', {game_id: @game_id, color: color}
    , (message) ->
      $t.player = message
      player_selector = '#p' + color
      $(player_selector).attr('data-state','input')
      $(player_selector+' input').first().focus()
      $('.player:not('+player_selector+')[data-state="choosing"]').attr('data-state','none')
      return
    , (message) ->
      return
    return

  set_name: (name) ->
    @dispatcher.trigger 'game.set_name', { id: @player.id, name: name, game_id: @game_id }

  roll: () ->
    @dispatcher.trigger 'game.roll', { id: @player.id, game_id: @game_id }

  move: (chess) ->
    if !@move_lock && (!in_airport(chess) || @steps == 6)
      @move_lock = true
      @dispatcher.trigger 'game.move', { id: @player.id, game_id: @game_id, move: chess }

  in_airport: (chess) ->
    return (chess >= 76 && chess < 92)

getTransitionEndEvent = () ->
  if @transition == undefined
    el = document.createElement('testSubject')
    transitions = {
      'transition':'transitionend',
      'OTransition':'oTransitionEnd',
      'MozTransition':'transitionend',
      'webkitTransition':'webkitTransitionEnd'
    }
    for k, v  of transitions
      if el.style[k] != undefined
        @transition = v
        break
  @transition

$.fn.extend
  correctPosition: ->
    return @each () ->
      $t = $(this)
      pos = $t.data('position')
      $t.css
        left: positions[pos][0] - 14.5
        top: positions[pos][1] - 14.5

  followPath: (path, shouldAnimated, callback) ->
    if path.length == undefined || path.length == 0
      if typeof callback == "function"
        callback()
      return
    @each () ->
      if typeof shouldAnimated == "function"
        flag = shouldAnimated()
      else
        flag == true

      $t = $(this)
      if flag
        $t.data('position', path.shift())
        $t.correctPosition()
        $t.on getTransitionEndEvent(), (event) ->
          if event.originalEvent.propertyName == 'top'
            $t.followPath path, shouldAnimated, callback
            $(this).off event
          false
      else
        $t.data('position', path[-1])
        $t.correctPosition()
        callback() if typeof callback == "function"
      return

game = new Game
$ ->
  game.connect($('#root_url').text()+'/websocket')
  $('.chess, .star').correctPosition()
  $('.player input').click false
  $('.player').click ->
    $t = $(this)
    state = $t.attr('data-state')
    if state == 'roll'
      $t.attr('data-state','rolling')
      game.roll()
    else if state == 'choosing'
      game.request_color($t.attr('id').slice(1))
    else if state == 'input'
      name = $t.find('input').first().val()
      $nd = $t.find('.name-display').first()
      $nd.text(name)
      $nd.attr('data-self','true')
      $t.attr('data-state','ready')
      game.set_name name
    return

  $('.chess').click ->
    $t = $(this)


  $('.player input').keypress (e) ->
    if e.which == 13
      $p = $(@).parents('.player').first().click()

  return
