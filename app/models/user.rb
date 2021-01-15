class User < ApplicationRecord
  belongs_to :app
  
  acts_as_paranoid
  if !Rails.env.test?
    searchkick
  end

  # Index name for a users is now:
  # classname_environment[if survey user has group, _groupmanagergroupname]
  # It has been overriden searchkick's class that sends data to elaticsearch, 
  # such that the index name is now defined by the model that is being 
  # evaluated using the function 'index_pattern_name'
  def index_pattern_name
    env = ENV['RAILS_ENV']
    if self.group.nil?
      return 'users_' + env
    end
    group_name = self.group.group_manager.group_name
    group_name.downcase!
    group_name.gsub! ' ', '-'
    return 'users_' + env + '_' + group_name
  end

  has_many :households,
    dependent: :destroy

  has_many :surveys,
    dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: JWTBlacklist

  belongs_to :app
  belongs_to :group, optional: true
  has_one :school_unit
    
  validates :user_name,
    presence: true,
    length: {
      in: 1..255,
      too_long: I18n.translate("user.validations.user_name.too_long"),
      too_short: I18n.translate("user.validations.user_name.too_short")
    }

  validates :password,
    presence: true,
    length: {
      in: 8..255,
      too_long: I18n.translate("user.validations.password.too_long"),
      too_short: I18n.translate("user.validations.password.too_short")
    }

  validates :email,
    presence: true,
    length: {
      in: 1..255,
      message: "Email deve seguir o formato: example@example.com"
    },
    format: { with: URI::MailTo::EMAIL_REGEXP, message: I18n.translate("validations.email.message") },
    uniqueness: true

  # Data that gets sent as fields for elastic indexes
  def search_data
    elastic_data = self.as_json(except:['app_id', 'group_id', 'aux_code', 'reset_password_token'])
    elastic_data[:app] = self.app.app_name
    if !self.group.nil?
      elastic_data[:group] = self.group.get_path(string_only=true, labeled=false).join('/')
    else
      elastic_data[:group] = nil
    end
    if !self.school_unit_id.nil? and SchoolUnit.where(id:self.school_unit_id).count > 0
      elastic_data[:enrolled_in] = SchoolUnit.where(id:self.school_unit_id)[0].description 
    else 
      elastic_data[:enrolled_in] = nil 
    end
    elastic_data[:household_count] = self.households.count
    return elastic_data 
  end

  def update_streak(survey)
    if survey.household_id
      obj = survey.household
      last_survey = Survey.where("household_id = ?", survey.household_id).order("id DESC").offset(1).first
    else
      obj = self
      last_survey = Survey.where("user_id = ?", self.id).order("id DESC").offset(1).first
    end

    if last_survey
      if last_survey.created_at.day == survey.created_at.prev_day.day
        obj.streak += 1
      elsif last_survey.created_at.day != survey.created_at.day
        obj.streak = 1
      end
    else
      obj.streak = 1
    end
    obj.update_attribute(:streak, obj.streak)
  end

  def get_feedback_message(survey)
    if survey.household_id
      obj = survey.household
    else
      obj = self
    end
    
    message = Message.where.not(feedback_message: [nil, ""]).where("day = ?", obj.streak).first
    if !message
      message = Message.where.not(feedback_message: [nil, ""]).where("day = ?", -1)
      index = obj.streak % message.size
      message = message[index]
    end
    return message.feedback_message
  end

  def analysis
      if self.created_at < Date.parse('2020-06-10')
        user_survey_limit_date = Date.parse('2020-09-30')
        user_created_at = Date.parse('2020-06-10')
      else
        user_survey_limit_date = self.created_at + 112.days
        user_created_at = self.created_at
      end

      user_surveys = Survey.where(user_id: self.id).where("DATE(created_at) >= ?", user_created_at).where("DATE(created_at) <= ?", user_survey_limit_date)

      user_total_surveys = user_surveys.count

      user_double_reports = user_surveys.select("DATE(created_at)").group("DATE(created_at)").having("count(*) > 1").size

      user_days_of_double_reports = user_double_reports.count

      sum = 0
      user_double_reports.each do |key, value| 
          sum =  sum + value
      end
    
      user_total_of_double_reports = sum

      total_reports = user_total_surveys - (user_total_of_double_reports - user_days_of_double_reports)
       

    return {count: total_reports, initial_date: user_created_at.to_formatted_s(:long),limit_date: user_survey_limit_date.to_formatted_s(:long)}
  end

  scope :user_by_app_id, ->(current_user_app_id) { where(app_id: current_user_app_id) }
end
