require 'digest/sha1'

class LdapUser < ActiveLdap::Base
  ldap_mapping :prefix => 'cn=users', :dn_attribute => 'uid', :classes => ['top', 'schoolwiresUser']
    # :scope => ::LDAP::LDAP_SCOPE_ONELEVEL
    
  before_save :encrypt_password
  
  # Clear text password, encrypted on save
  attr_accessor :password    
  
  class << self
    # This was find_by_login in the active_ldap generator
    # but we are using an alias for id (to work with restful_authentication)
    def find_by_id(username)
      begin
        user = find(:first, :attribute => 'uid', :value => username)
        # user = find(:attribute => 'uid', :value => username, 
        #  :attributes => ['uid', 'mail', 'givenName', 'sn', 'swUserRole', 'employeeType', 'description'])
      rescue ActiveLdap::EntryNotFound
        nil
      end
    end
    
    def authenticate(username, password)
      return nil if username.blank? || password.blank?
      u = find_by_id(username)
      u && u.authenticated?(password) ? u : nil
    end
    
    def change_pending_password(pu)
      user = find_by_id(pu.user_id)
      user.nil? ? false : user.change_crypted_password(pu.crypted_password)
    end
  end
  
  # Since we are not backed by a database, we need to either supply these
  # as ldap attributes (changing the schema) or via some other method.
  def login
    uid
  end
  
  def email
    mail
  end
  
  def first_name
    givenName
  end
  
  def last_name
    sn
  end

  def email=(value)
    write_attribute :mail, (value ? value.downcase : nil)
  end
  
  def short_dn
    @short_dn ||=
      (ActiveLdap::DN.parse(dn) - ActiveLdap::DN.parse(self.class.base)).to_s
  end

  def system_user
    @system_user ||= User.find_by_dn(dn)
  end

  # more functions
  def authenticated?(password)
    begin
      bind(password)
      true
    rescue ActiveLdap::AuthenticationError,
      ActiveLdap::LdapError::UnwillingToPerform
      false
    end
  end
  
  def can_change_password?
    description == 'user'
  end
  
  private
  
  def encrypt_password
    return if password.blank?
    hash_type = "crypt"
    if /\A\{([A-Z][A-Z\d]+)\}/ =~ user_password.to_s
      hash_type = $1.downcase
    end
    self.user_password = ActiveLdap::UserPassword.send(hash_type, password)
  end
end
