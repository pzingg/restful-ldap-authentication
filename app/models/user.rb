class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByCookieToken
  # include Authentication::ByPassword

  # validates_presence_of     :login
  # validates_length_of       :login,    :within => 3..40
  # validates_uniqueness_of   :login
  # validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  # validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  # validates_length_of       :name,     :maximum => 100

  # validates_presence_of     :email
  # validates_length_of       :email,    :within => 6..100 #r@a.wk
  # validates_uniqueness_of   :email
  # validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # attr_accessible :login, :email, :name, :password, :password_confirmation

  # Temporary attributes for change password
  attr_accessor :new_password, :password_confirmation

  # Clear text password, encrypted on save
  attr_accessor :password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  class << self
    # This was find_by_login in the active_ldap generator
    # but we are using an alias for id (to work with restful_authentication)
    def find_by_id(username)
      user = find_by_login(username)
      user ||= ldap_create(username)
    end
    
    def ldap_create(username)
      user = nil
      lu = LdapUser.find(:first, :attribute => 'uid', :value => username) rescue nil
      # lu = LdapUser.find(:attribute => 'uid', :value => username, 
      #  :attributes => ['uid', 'mail', 'givenName', 'sn', 'swUserRole', 'employeeType', 'description', 'userPassword'])
      if lu
        user = create(:login => lu.uid, 
          :email => lu.mail, 
          :user_password => lu.user_password, 
          :description => lu.description)
        user.ldap_user = lu
      end
      user
    end
  
    def authenticate(username, password)
      return nil if username.blank? || password.blank?
      user = find_by_id(username)
      user && user.authenticated?(password) ? user : nil
    end
  
    def change_pending_password(pu)
      user = find_by_id(pu.user_id)
      user.nil? ? false : user.change_crypted_password(pu.crypted_password)
    end
  end

  def ldap_user=(lu)
    @ldap_user = lu
  end

  def ldap_user
    @ldap_user ||= LdapUser.find(:first, :attribute => 'uid', :value => self.login) rescue nil
  end
  
  def id
    login
  end

  def can_change_password?
    description == 'user'
  end

  PW_ALPHA = ('a'..'z').to_a - ['i','l','o']
  PW_NUMERIC = ('2'..'9').to_a
  
  def create_pending_password
    new_password = ''
    2.times { |i| new_password << PW_ALPHA[rand(PW_ALPHA.size)] }
    4.times { |i| new_password << PW_NUMERIC[rand(PW_NUMERIC.size)] }
  
    crypted_password = ActiveLdap::UserPassword.crypt(new_password.downcase)
    PendingUser.delete_all(['user_id=?', self.id])
    pu = PendingUser.create(:user_id => self.id, :crypted_password => crypted_password)
  
    UserMailer.deliver_resetpw_notification(self, new_password, pu.activation_code)
  end

  def change_password(new_password)
    change_crypted_password(ActiveLdap::UserPassword.crypt(new_password.downcase))
  end

  def change_crypted_password(crypted_password)
    return false if crypted_password.blank?
    lu = ldap_user
    return false unless lu
    update_attribute(:user_password, crypted_password)
    lu.update_attribute(:user_password, crypted_password)
    true
  end
  
  def authenticated?(password)
    if self.user_password.blank? || !(/^\{crypt\}/i =~ self.user_password)
      lu = ldap_user
      auth = lu ? lu.authenticated?(password) : false
      logger.warn "authenticating via ldap bind #{password} -> #{auth ? 'succeeded' : 'failed'}"
      return auth
    end
    salt = ActiveLdap::UserPassword.extract_salt_for_crypt($POSTMATCH)
    crypted_password = ActiveLdap::UserPassword.crypt(password.downcase, salt)
    logger.warn "authenticating via cache #{password} -> #{crypted_password} against #{self.user_password}, salt #{salt}"
    crypted_password[7,] == self.user_password[7,]
  end
end