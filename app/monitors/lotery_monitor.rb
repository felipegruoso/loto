class LoteryMonitor

  def self.run(type)
    LoteryMonitor.new(type).run
  end

  def initialize(type)
    @type = type
    @game = Game.where(name: @type).first
  end

  def run
    last_update = @game.updated_at.to_date
    result      = Scrapers::Lotery.run(@type, last_update)

    if result[:code] == Scrapers::StatusCodes::SUCCESS
      persist(result)
    end
  end

  def persist(result)
    raffle = {
      raffle_number: result[:data][:raffle_number],
      numbers:       result[:data][:numbers],
      game_id:       @game.id
    }

    r = Raffle.create(raffle)
    if r.persisted?
      @game.update_attributes(updated_at: result[:data][:date])
    end

  end

end
