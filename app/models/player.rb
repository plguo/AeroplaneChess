class Player < ActiveRecord::Base
  belongs_to :game, touch: true
  enum name: [:blue, :yellow, :green, :red]
  enum state: [:waiting, :typing_name, :ready]
  serialize: raw_chesses, JSON
end
