class ChessesGroup
  def self.dump(object)
=begin
    #Check is unnecessary for an internal class
    unless object.is_a?(Array) && object.length == 4 && object.all? {|e| e.is_a?(Chess)}
      raise ::ActiveRecord::SerializationTypeMismatch,
        "Attribute was supposed to be an Array object contains 4 Chess objects"
    end
=end

    return if object.nil?
    data = object[0].color.to_s
    object.each do |element|
      data += element.position < 10 ? "0#{element.position}" : element.position.to_s
      data += element.finished ? 'T' : 'F'
    end
    data
  end

  def self.load(raw)
    return if raw.blank?
    color = raw[0].to_i
    4.times.map do |index|
      info = raw[(index*3+1),3]
      Chess.new(color, index, info[0..1].to_i, info[2]=='T')
    end
  end
end

class Chess
  attr_reader :color, :id, :position, :finished

  def initialize(color, id, position, finished)
    @color = color.to_i
    @id = id.to_i
    @position = position.to_i
    @finished = finished == true
    unless (0..3).include?(@color) && (0..3).include?(@id) && valid_position?
      raise ArgumentError
    end
  end

  def move_by!(steps)
    if in_airport?
      @position = @color + 92
      { chess: self.to_id, path: [@position], finished: (@finished = false), flyby: nil }
    elsif on_runway?
      path_info = path(runway_exit,steps-1)
      path = path_info[0...(-1)].unshift(runway_exit)
      @position = path[-1]
      { chess: self.to_id, path: path, finished: (@finished = false), flyby: nil }
    else
      path_info = path(@position,steps)
      @position = path_info[-2]
      back_to_airport! if @finished = (@position == (57 + @color * 6))
      { chess: self.to_id, path: path_info[0...(-1)], finished: @finished, flyby: path_info[-1] }
    end
  end

  def back_to_airport!
    @position = 76 + @color * 4 + @id
  end

  def position_after(steps)
    unless in_airport?
      @@position_after_cache ||= Hash.new
      cache_key = position * 6 + steps - 1
      if @@position_after_cache[cache_key].nil?
        if on_runway?
           @@position_after_cache[cache_key] =  path(runway_exit, steps)[-2]
        else
          @@position_after_cache[cache_key] =  path(@position, steps)[-2]
        end
      end
      @@position_after_cache[cache_key]
    else
      nil
    end
  end

  def valid_position?
    @position < 52 || ((@color * 6 + 52)..(@color * 6 + 57)).include?(@position) || ((@color * 4 + 76)..(@color * 4 + 79)).include?(@position) || (@color + 92) == @position
  end

  def valid_move?(steps)
    !@finished && ( steps == 6 || !in_airport? )
  end

  def in_airport?
    _in_airport? @position
  end

  def on_runway?
    _on_runway? @position
  end

  def to_info
    [@position, @finished]
  end

  def to_id
    "#{@color}#{@id}"
  end

  def self.on_runway_for_color(color)
    self.new(color, 0, (color + 92), false)
  end

  private
  def path(start, steps)
    if steps <= 0
      if super_jump? start
        case @color
        when 0
          [17, 66 , 29, 66]
        when 1
          [30, 72, 42, 72]
        when 2
          [43, 54, 3, 54]
        when 3
          [4, 60, 16, 60]
        else
        end
      elsif long_jump? start
        case @color
        when 0
          [66 , 29, 66]
        when 1
          [72, 42, 72]
        when 2
          [54, 3, 54]
        when 3
          [60, 16, 60]
        else
        end
      elsif short_jump? start
        [((start + 4) % 52), nil]
      else
        [nil]
      end
    elsif (52..75).include? start
      if start == (57 + @color * 6)
        subpath = []
        for i in 1..steps
          subpath << (start - i)
        end
        subpath << [nil]
      else
        path(start + 1, steps - 1).unshift(start + 1)
      end
    else
      if entrance? start
        next_pos = 52 + @color * 6
      else
        next_pos = (start + 1) % 52
      end
      path(next_pos, steps - 1).unshift(next_pos)
    end
  end

  def short_jump?(pos)
    (0..51).include?(pos) && !entrance?(pos) && ((pos - 1) % 4 == @color)
  end

  def long_jump?(pos)
    pos == [17, 30, 43, 4][@color]
  end

  def super_jump?(pos)
    pos == [13, 26, 39, 0][@color]
  end

  def entrance?(pos)
    pos == [49, 10, 23, 36][@color]
  end

  def _in_airport?(pos)
    ((@color * 4 + 76)..(@color * 4 + 79)).include?(pos)
  end

  def _on_runway?(pos)
    (@color + 92) == pos
  end

  def runway_exit
    @color * 13
  end

end
