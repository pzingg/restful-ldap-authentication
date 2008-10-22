class UsersController < ApplicationController
  
  def activate
    logout_keeping_session!
    user = PendingUser.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user
      if user.activate!
        flash[:notice] = "Activation complete!"
      else
        flash[:error] = "There was a system problem activating your request."
      end
      redirect_to '/'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email?"
      redirect_back_or_default('/')
    end
  end
  
  def pwchanged
    logout_keeping_session!
    user = PendingUser.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user
      if user.change_user_password!
        flash[:notice] = "Your password was reset!"
      else
        flash[:error] = "There was a system problem resetting your password."
      end
      redirect_to '/'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email?"
      redirect_back_or_default('/')
    end
  end
end
