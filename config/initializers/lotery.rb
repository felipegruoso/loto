module Lotery

  GAMES = YAML.load_file("#{Rails.root}/config/games.yml")[:games]

  GAMES_TYPE = GAMES.map { |game| game[:type] }

end
