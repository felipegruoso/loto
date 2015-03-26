class Game < ActiveRecord::Base
  attr_accessible :name, :updated_at

  has_many :raffles
end
