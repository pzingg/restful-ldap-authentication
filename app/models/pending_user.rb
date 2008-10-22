class PendingUser < ActiveRecord::Base
  before_create :make_activation_code
  
  def make_activation_code
    self.activation_code = User.make_token
  end

  def change_user_password!
    changed = User.change_pending_password(self)
    self.destroy
    changed
  end

  def activate!
    activated = !user.nil?
    self.destroy
    activated
  end
end
