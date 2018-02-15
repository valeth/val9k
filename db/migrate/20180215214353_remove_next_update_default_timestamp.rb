class RemoveNextUpdateDefaultTimestamp < ActiveRecord::Migration[5.1]
  def change
    change_column_null :youtube_channels, :next_update, true
    change_column_default :youtube_channels, :next_update, nil
  end
end
