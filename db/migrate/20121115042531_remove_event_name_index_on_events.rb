# frozen_string_literal: true

class RemoveEventNameIndexOnEvents < ActiveRecord::Migration[7.1]
  def up
    remove_index "events", "event_type"
  end

  def down
    add_index "events", "event_type"
  end
end
