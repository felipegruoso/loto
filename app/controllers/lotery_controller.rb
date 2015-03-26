# encoding: utf-8

class LoteryController < ApplicationController

  def index
  end

  def game
    @game = Lotery::GAMES.select { |game| game[:type] == params['game'] }.first
  end

  def list
    @game    = Lotery::GAMES.select { |game| game[:type] == params['game'] }.first
    game     = Game.where(name: params['game']).first
    @results = Raffle.where(game_id: game.id)
  end

  def check
  end

  def generate
  end

  def probabilities
  end

  def already
    @game = Lotery::GAMES.select { |game| game[:type] == params['game'] }.first
  end

  def check_already
    success = LoteryUtils.check(params[:content], params[:game])
      
    if success.present?
      @results = success
      respond_to do |format|
        format.html { render 'lotery/results', layout: false }
      end
    else
      flash.now[:error] = "Seu jogo ainda não saiu!"
      respond_to do |format|
        format.html { render 'layouts/flash', layout: false }
      end
    end

  end

end
