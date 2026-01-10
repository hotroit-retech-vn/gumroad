# frozen_string_literal: true

class PriceCents < ActiveRecord::Migration[7.1]
  def up
    add_column :links, :price_cents, :integer
    add_column :purchases, :price_cents, :integer

    # Use raw SQL to avoid loading models during migration
    execute "UPDATE links SET price_cents = CAST(price * 100 AS INTEGER) WHERE price IS NOT NULL"
    execute "UPDATE purchases SET price_cents = CAST(price * 100 AS INTEGER) WHERE price IS NOT NULL"
  end

  def down
    remove_column :links, :price_cents
    remove_column :purchases, :price_cents
  end
end
