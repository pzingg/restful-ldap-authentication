if RAILS_ENV != 'test'
  c = YAML::load(File.open("#{RAILS_ROOT}/config/smtp.yml"))
  if c.key?(RAILS_ENV)
    ActionMailer::Base.smtp_settings = {
      :address => c[RAILS_ENV]['address'],
      :port => c[RAILS_ENV]['port'],
      :domain => c[RAILS_ENV]['domain'],
      :authentication => c[RAILS_ENV]['authentication'],
      :user_name => c[RAILS_ENV]['user_name'],
      :password => c[RAILS_ENV]['password']
    }
  end
end
