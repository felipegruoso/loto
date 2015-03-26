class Raffle < ActiveRecord::Base
  attr_accessible :game_id, :numbers, :raffle_number, :date
  serialize :numbers

  belongs_to :game
  validates_existence_of :game
  validates_uniqueness_of :raffle_number
end
