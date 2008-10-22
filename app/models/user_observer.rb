# Not using signup/activation right now

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    # uncomment if you have problems
    # user.reload 
    UserMailer.deliver_signup_notification(user)
  end

  def after_save(user)
    # uncomment if you have problems
    # user.reload
    UserMailer.deliver_activation(user) if user.recently_activated?
  end
end
