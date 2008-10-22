class PasswordsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update]
    
  def index
  end
  
  def update
    return unless current_user_can_change_password?
    changed = false
    system_error = false
    password = params[:user][:new_password]
    confirm  = params[:user][:password_confirmation]
    if password.blank?
      flash[:error] = 'Please supply a password'
    elsif !(6..20).include? password.size
      flash[:error] = 'Passwords must be between 6 and 20 characters'
    elsif !Authentication.password_regex.match(password)
      flash[:error] = Authentication.bad_password_message
    elsif password != confirm
      flash[:error] = "Passwords don't match"
    else
      changed = current_user.change_password(password)
      if changed
        flash[:notice] = 'Your password was successfully changed'
      else
        flash[:error] = 'There was a problem changing your password'
        system_error = true
      end
    end
    if changed || system_error
      redirect_to '/'
    else
      redirect_to '/changepw'
    end
  end
  
  def edit
    return unless current_user_can_change_password?
    @user = current_user
  end
  
  def reset
    found_user = nil
    @reset_user = ResetUser.new
    if request.post?
      @reset_user.email = params[:reset_user][:email]
      @reset_user.login = params[:reset_user][:login]
      if @reset_user.email.blank?
        flash[:error] = 'Please supply an email address'
      else
        any_users = User.find(:all, :attribute => :mail, :value => @reset_user.email)
        num_users = any_users.size
        if num_users == 1
          found_user = any_users.first
        elsif num_users == 0
          flash[:error] = 'No user found with that email address'
        elsif @reset_user.login.blank?
          flash[:error] = 'Please supply a user name'
        else
          found_users = any_users.select { |u| u.id == @reset_user.login.downcase }
          if found_users.size != 1
            flash[:error] = 'No user found with that username'
          else
            found_user = found_users.first
          end
        end  
      end
      if found_user
        found_user.create_pending_password
        flash[:notice] = 'An email was sent with your new password'
        redirect_to '/'
      end
    end
  end
  
  protected
  
  def current_user_can_change_password?
    unless current_user.can_change_password?
      flash[:error] = 'This user cannot change passwords.'
      redirect_to '/'
      return false
    end
    true
  end
end
