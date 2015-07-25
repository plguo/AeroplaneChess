# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
positions = [[195, 561], [180, 522], [180, 486], [195, 447], [165, 417], [126, 432], [90, 432], [51, 417], [36, 378], [36, 342], [36, 306], [36, 270], [36, 234], [51, 195], [90, 180], [126, 180], [165, 195], [195, 165], [180, 126], [180, 90], [195, 51], [234, 36], [270, 36], [306, 36], [342, 36], [378, 36], [417, 51], [432, 90], [432, 126], [417, 165], [447, 195], [486, 180], [522, 180], [561, 195], [576, 234], [576, 270], [576, 306], [576, 342], [576, 378], [561, 417], [522, 432], [486, 432], [447, 417], [417, 447], [432, 486], [432, 522], [417, 561], [378, 576], [342, 576], [306, 576], [270, 576], [234, 576], [306, 519], [306, 483], [306, 447], [306, 411], [306, 375], [306, 339], [93, 306], [129, 306], [165, 306], [201, 306], [237, 306], [273, 306], [306, 93], [306, 129], [306, 165], [306, 201], [306, 237], [306, 273], [519, 306], [483, 306], [447, 306], [411, 306], [375, 306], [339, 306], [41, 571], [41, 509], [103, 509], [103, 571], [41, 103], [41, 41], [103, 41], [103, 103], [509, 103], [509, 41], [571, 41], [571, 103], [509, 571], [509, 509], [571, 509], [571, 571], [165, 591], [21, 165], [447, 21], [591, 447]]

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
        left: positions[pos][0] - 15
        top: positions[pos][1] - 15

  followPath: (path, shouldAnimated, callback) ->
    if path.length == undefined || path.length == 0
      callback() if typeof callback == "function"
      return

    flag = true
    if typeof shouldAnimated == "function"
      flag = shouldAnimated()
    return unless flag

    $t = $(this).first()

    $t.data('position', path.shift())
    $t.correctPosition()

    setTimeout () ->
      $t.on getTransitionEndEvent(), (event) ->
        if event.originalEvent.propertyName == 'top' || event.originalEvent.propertyName == 'left'
          $(this).off event
          $t.followPath path, shouldAnimated, callback
        false
    , 250
    return

setCountIndicators = (data) ->
  for color, count_data of data
    $("#map .count-indicator.color-#{color}").remove()
    for pos, count of count_data
      $("<div class=\"count-indicator color-#{color}\">#{count}</div>").css({
        left: positions[pos][0] - 8
        top: positions[pos][1] - 8
      }).appendTo('#map');

class Game
  constructor: ->
    @player = {id: -1, color: -1}

  set_channel: (channel_name) ->
    $t = @
    @channel = @dispatcher.subscribe(channel_name)
    @channel.bind 'update', (message) ->
      oldState = $t.state
      $t.state = message.state
      $t.turn = message.turn
      $t.steps = message.steps
      $t.players = message.players
      $t.movables = message.movables
      $t.stage = message.stage
      $t.count_data = message.count
      $t.update(oldState)
      return

    @channel.bind 'move', (message) ->
      $t.state = 'moving'
      $t.stage = message.stage
      path = message.path
      player = $t.players[$t.turn]
      player[0] = path[-1]
      player[1] = message.finished
      collided = message.collided
      count_data = message.count
      finished_message = { game_id: $t.game_id, stage: $t.stage }
      turn = $t.turn

      if $t.turn == $t.player.color
        $(".chess[id^=\"c#{$t.turn}\"][data-movable=true]").attr('data-movable','false')

      $('#map').attr('animated-move','true')
      setCountIndicators(message.start_count)
      chess_sel = '#c' + message.chess
      $(chess_sel).attr('data-moving','true')
      $(chess_sel).followPath message.path
      , () ->
        $('#map').attr('animated-move') == 'true'
      , () ->
        setCountIndicators(count_data)
        $(chess_sel).attr('data-moving','false')

        any_collision = false
        $coll = null
        for c in collided
          any_collision = true
          $coll = $("#c#{c}")
          $coll.data('position', $("#s#{c}").data('position'))
          $coll.correctPosition()

        move_finished_callback = () ->
          $('#map').attr('animated-move','false')
          $t.dispatcher.trigger('game.move_finished', finished_message)

        if any_collision
          $coll.on getTransitionEndEvent(), (event) ->
            if event.originalEvent.propertyName == 'top' || event.originalEvent.propertyName == 'left'
              $(this).off event
              move_finished_callback()
              false
        else
          move_finished_callback()
      return
    return

  connect: (url) ->
    $t = @
    @dispatcher = new WebSocketRails(url)

    @dispatcher.bind 'log', (msg) ->
      console.log(msg)

    @dispatcher.trigger 'game.new', {}
    , (message) ->
      $t.game_id = message.game_id
      $t.state = message.state
      $t.turn = message.turn
      $t.steps = message.steps
      $t.players = message.players
      $t.stage = message.stage
      $t.update()
      $t.set_channel('G'+$t.game_id)
      return
    , (message) ->
      return

    return

  update: (oldState) ->
    self = @
    player_data = ['','','','']
    color = 0
    for player in @players
      if player.state == "waiting" && self.player.color == -1
        player_data[color] = 'choosing'
      else if player.state == "typing_name"
        player_data[color] = 'typing' if color != self.player.color
      else if player.state == "ready" && @state == "waiting"
        player_data[color] = 'ready'
      else
        player_data[color] = 'none'

      $('#p'+color+' .name-display').first().text(player.name) if player.name != null
      color += 1

    if @state == 'roll'
      if @turn == @player.color
        player_data[@turn] = 'roll'
      else
        player_data[@turn] = 'waiting'
    else if @state == 'rolling'
      player_data[@turn] = 'rolling'
      $t = @
      stage = @stage
      setTimeout () ->
        if $t.state == 'rolling'
          $t.dispatcher.trigger 'game.roll_finished', { game_id: $t.game_id, stage: stage}
      , 500
    else if @state == 'move' || @state == 'moving'
      player_data[@turn] = 'move'
      $('#p'+@turn+' .dice').first().attr('data-face', @steps)
      if @state == 'move'
        if @turn == @player.color
          if @movables.length == 0
            player_data[@turn] = 'next'
          else
            for movable_chess in @movables
              $("#c#{@turn}#{movable_chess}").attr('data-movable','true')

    for color, state of player_data
      $('#p'+color).attr('data-state',state) unless state == ''

    if oldState == 'moving'
      $('#map').attr('animated-move','false')
      for player_index, player of @players
        for chess_index ,chess of player.chesses
          if chess[1]
            c_id = "#{player_index}#{chess_index}"
            c_chess = $("#c#{c_id}")
            c_chess.data('position', $("#s#{c_id}").data('position'))
            c_chess.attr('data-finished', 'true')
          else
            $("#c#{player_index}#{chess_index}").data('position',chess[0])
      $('.chess').correctPosition();
      console.log(@count_data)
      setCountIndicators(@count_data)

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
    @dispatcher.trigger 'game.roll', { id: @player.id, game_id: @game_id, stage: @stage }

  move: (chess) ->
    if (parseInt(chess) in @movables)
      @dispatcher.trigger 'game.move', { id: @player.id, game_id: @game_id, move: chess, stage: @stage }

  in_airport: (chess) ->
    return (chess >= 76 && chess < 92)

  next: (chess) ->
    @dispatcher.trigger 'game.next', { game_id: @game_id, stage: @stage }

  snapshot: ()->
    obj = {
      game_id: @game_id
      state: @state
      turn: @turn
      steps: @steps
      players: JSON.parse(JSON.stringify(@players))
      player: JSON.parse(JSON.stringify(@player))
    }
    if @movables != undefined
      obj.movables =  JSON.parse(JSON.stringify(@movables))
    obj

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
    else if state == 'next'
      game.next()
    return

  $('.chess').click ->
    if game.turn == game.player.color && game.state == 'move'
      game.move($(this).attr('id')[2])
    return

  $('.player input').keypress (e) ->
    if e.which == 13
      $p = $(@).parents('.player').first().click()
    return

  return
