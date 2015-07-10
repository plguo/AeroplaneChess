class GamesController < ApplicationController
  def index
  end
  def destroy
    Game.destroy_all
    redirect_to root_path
  end
end
