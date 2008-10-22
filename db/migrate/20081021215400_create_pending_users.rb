class CreatePendingUsers < ActiveRecord::Migration
  def self.up
    create_table :pending_users do |t|
      t.string  :user_id, :limit => 40, :null => false
      t.string  :activation_code, :limit => 40, :null => false
      t.string  :crypted_password, :limit => 60
      t.timestamps
    end
  end

  def self.down
    drop_table :pending_users
  end
end
