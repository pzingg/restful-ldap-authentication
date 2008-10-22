class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table 'users', :id => false, :force => true do |t|
      t.string   :login, :limit => 40
      t.string   :email, :limit => 100
      t.string   :user_password, :limit => 60
      t.string   :description, :limit => 40
      t.string   :remember_token, :limit => 40
      t.datetime :remember_token_expires_at
      t.timestamps
    end
    add_index :users, :login, :unique => true
  end

  def self.down
    drop_table 'users'
  end
end
