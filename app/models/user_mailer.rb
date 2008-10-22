class UserMailer < ActionMailer::Base
  
  def resetpw_notification(user, new_password, activation_code)
    setup_email(user)
    
    @subject    += 'Please activate your reset password'
    @body[:new_password] = new_password
    @body[:url]  = pwchanged_url(:activation_code => activation_code)
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://YOURSITE/"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "ADMINEMAIL"
      @subject     = "[YOURSITE] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
