class User < ActiveRecord::Base
  has_many :accounts, :dependent => :destroy
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  TEMP_EMAIL_PREFIX = 'change@me'
  TEMP_EMAIL_REGEX = /\Achange@me/
  validates_format_of :email, :without => TEMP_EMAIL_REGEX, on: :update

  def self.find_for_oauth(auth, signed_in_resource = nil)
    account = Account.find_for_oauth(auth)
    user = signed_in_resource ? signed_in_resource : account.user

    # Create the user if needed
    if user.nil?

      email = auth.info.email
      user = email ? User.where(:email => email).first :  User.where(:username => auth.info.nickname).first

      # Create the user if it's a new registration
      if user.nil?
        user = User.new(
            name: auth.extra.raw_info.name,
            email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com",
            username: auth.info.nickname ? auth.info.nickname : auth.uid,
            password: Devise.friendly_token[0,20]
        )
        save_user_account(user, account)
        user.skip_confirmation!
        user
      else
        save_user_account(user, account)
      end
    end
    user
  end

  def email_verified?
    self.email && self.email !~ TEMP_EMAIL_REGEX
  end

  def self.save_user_account(user, account)
    user.accounts << account
    user.save!
  end
end
