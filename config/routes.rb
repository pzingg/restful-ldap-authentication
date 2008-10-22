ActionController::Routing::Routes.draw do |map|
  map.resource :session
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'

  map.resources :users
  # map.register '/register', :controller => 'users', :action => 'create'
  # map.signup '/signup', :controller => 'users', :action => 'new'
  map.activate  '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil 
  map.pwchanged '/pwchanged/:activation_code', :controller => 'users', :action => 'pwchanged', :activation_code => nil 
  
  map.root :controller => 'passwords', :action => 'index'
  map.updatepw '/updatepw', :controller => 'passwords', :action => 'update'
  map.changepw '/changepw', :controller => 'passwords', :action => 'edit'
  map.resetpw '/resetpw', :controller => 'passwords', :action => 'reset'
end
