class AlterUsersAddOAuthCols < ActiveRecord::Migration
  def change
    add_column :users, :google_token, :string
    add_column :users, :google_refresh_token, :string
    add_column :users, :google_token_expiration, :string
    add_column :users, :first_name, :string
    add_column :users, :timezone_offset, :integer
  end
end
