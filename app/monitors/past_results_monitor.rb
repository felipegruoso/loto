class PastResultsMonitor

  def self.run(game)
    PastResultsMonitor.new(game).run
  end

  def initialize(game)
    @game = game
  end

  def run
    results = Scrapers::Populator.run(@game)

    if results[:code] == Scrapers::StatusCodes::SUCCESS
      game = Game.where(name: @game).first

      results[:data].each do |result|
        raffle = {
          numbers:       result[:numbers],
          raffle_number: result[:raffle_number],
          date:          result[:date],
          game_id:       game.id
        }

      r = Raffle.create(raffle)
      if r.persisted?
        game.updated_at = result[:date]
        game.save
      end

      end

    end
    
  end

end
