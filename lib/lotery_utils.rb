module LoteryUtils

  def self.check(content, game)
    klass = Lotery::GAMES.select { |g| g[:type] == game }.first

    games        = content.split(/(\r*\n)+/)

    min_quantity = klass[:quantity_of_numbers]
    max_quantity = klass[:max_numbers]
    min_number   = klass[:zero_allowed] ? 0 : 1
    max_number   = klass[:number_limit]
    
    valids = []
    games.map do |line|
      g       = line.split(/[ ;]+/)
      numbers = g.select do |num|
        num.match(/[\d]/) &&
        num.to_i.between?(min_number, max_number) 
      end

      if numbers.uniq.size.between?(min_quantity, max_quantity)
        g = g.map { |number| number.rjust(2, '0') }
        valids << g 
      end
    end

    raffles = Raffle.all
    success = []
    valids.each do |valid|
      success += raffles.select { |raffle| raffle.numbers - valid == [] }
    end

    success.uniq
  end

end
