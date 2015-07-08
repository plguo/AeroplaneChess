# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
positions = [[196.8,559.2],[180.0,522.0],[180.0,486.0],[196.8,448.8],[163.2,415.2],[126.0,432.0],[90.0,432.0],[52.8,415.2],[36.0,378.0],[36.0,342.0],[36.0,306.0],[36.0,270.0],[36.0,234.0],[52.8,196.8],[90.0,180.0],[126.0,180.0],[163.2,196.8],[196.8,163.2],[180.0,126.0],[180.0,90.0],[196.8,52.8],[234.0,36.0],[270.0,36.0],[306.0,36.0],[342.0,36.0],[378.0,36.0],[415.2,52.8],[432.0,90.0],[432.0,126.0],[415.2,163.2],[448.8,196.8],[486.0,180.0],[522.0,180.0],[559.2,196.8],[576.0,234.0],[576.0,270.0],[576.0,306.0],[576.0,342.0],[576.0,378.0],[559.2,415.2],[522.0,432.0],[486.0,432.0],[448.8,415.2],[415.2,448.8],[432.0,486.0],[432.0,522.0],[415.2,559.2],[378.0,576.0],[342.0,576.0],[306.0,576.0],[270.0,576.0],[234.0,576.0],[306.0,520.8],[306.0,484.8],[306.0,448.8],[306.0,412.8],[306.0,376.8],[306.0,340.8],[91.2,306.0],[127.2,306.0],[163.2,306.0],[199.2,306.0],[235.2,306.0],[271.2,306.0],[306.0,91.2],[306.0,127.2],[306.0,163.2],[306.0,199.2],[306.0,235.2],[306.0,271.2],[520.8,306.0],[484.8,306.0],[448.8,306.0],[412.8,306.0],[376.8,306.0],[340.8,306.0],[40.8,571.2],[40.8,508.8],[103.2,508.8],[103.2,571.2],[40.8,103.2],[40.8,40.8],[103.2,40.8],[103.2,103.2],[508.8,103.2],[508.8,40.8],[571.2,40.8],[571.2,103.2],[508.8,571.2],[508.8,508.8],[571.2,508.8],[571.2,571.2],[163.2,592.8],[19.2,163.2],[448.8,19.2],[592.8,448.8]]

log = (obj) ->
  console.log(obj)

class Game
  @player = {id: 0, color: 0}

  set_channel: (channel_name) ->
    $t = @
    @channel = @dispatcher.subscribe(channel_name)
    @channel.bind 'update', (message) ->
      $t.state = message.state
      $t.players = message.players

  connect: (url) ->
    $t = @
    @dispatcher = new WebSocketRails(url)

    @dispatcher.bind 'log', (msg) ->
      log(msg)

    @dispatcher.trigger 'game.new', {}
    , (message) ->
      log message
      $t.game_id = message.game_id
      $t.state = message.state
      $t.players = message.players
      $t.set_channel('G'+$t.game_id)
      return
    , (message) ->
      return

    return

  update: ->
    for player, i of @players
      if player.state == "waiting"
        $('#p'+i).attr('data-state','choosing')
      else if player.state == "typing_name"
        $('#p'+i).first().attr('data-state','typing')
      else if player.state == "ready"
        $('#p'+i).first().attr('data-state','ready')

  request_color: (color) ->
    $t = @
    log 'Rqs'
    @dispatcher.trigger 'game.request_color', {game_id: @game_id, color: color}
    , (message) ->
      log message
      log color
      $t.player = message
      $('#p'+color).attr('data-state','input')
      $('#p'+color+' input').first().focus()
      return
    , (message) ->
      return
    return

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

  followPath: (path) ->
    return if path.length == undefined || path.length == 0
    @each () ->
      $t = $(this)
      $t.data('position', path.shift())
      $t.correctPosition();
      $t.on getTransitionEndEvent(), (event) ->
        if event.originalEvent.propertyName == 'top'
          $t.followPath path
          $(this).off event
        false

game = new Game
$ ->
  game.connect($('#root_url').text()+'/websocket')
  $('.chess, .star').correctPosition()
  $('.player input').click false
  $('.player').click ->
    $t = $(this);
    if $t.attr('data-state') == 'roll'
      $dice = $t.find('.dice-box .dice').first()
      if $dice.attr('data-rotate') == 'true'
        $dice.attr('data-rotate','false')
        $t.attr('data-state','roll')
      else
        $dice.attr('data-rotate','true')
        $t.attr('data-state','none')
      true
    else if $t.attr('data-state') == 'choosing'
      game.request_color($t.attr('id').slice(1))
  true
