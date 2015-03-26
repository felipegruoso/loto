class CreateRaffles < ActiveRecord::Migration
  def change
    create_table :raffles do |t|
      t.text    :numbers
      t.integer :game_id
      t.string  :raffle_number
      t.date    :date

      t.timestamps
    end
  end
end
