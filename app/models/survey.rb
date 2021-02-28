class Survey < ApplicationRecord
  acts_as_paranoid
  require 'net/http'
  require 'httparty'
  if !Rails.env.test?
    searchkick
  end

    
  # Index name for a survey is now:
  # classname_environment[if survey user has group, _groupmanagergroupname]
  # It has been overriden searchkick's class that sends data to elaticsearch, 
  # such that the index name is now defined by the model that is being 
  # evaluated using the function 'index_pattern_name'  
  def index_pattern_name
    env = ENV['RAILS_ENV']
    if self.user.group.nil?
      return 'surveys_' + env
    end
    group_name = self.user.group.group_manager.group_name
    group_name.downcase!
    group_name.gsub! ' ', '-'
    return 'surveys_' + env + '_' + group_name
  end

  belongs_to :user
  belongs_to :household, optional:true
  before_validation :reverse_geocode

  serialize :symptom, Array

  def address
    [street, city, state, country].compact.join(', ')
  end
  
  reverse_geocoded_by :latitude, :longitude do |obj,results|
    if geo = results.first
      obj.city    = geo.city
      obj.country = geo.country
      obj.street  = geo.street
      obj.state   = geo.state
    end
  end
  
  def get_message(user)
    @user_symptoms = []
    symptom.map { |symptom|
      if Symptom.where(:code=>symptom).any?
        @user_symptoms.append(Symptom.where(:code=>symptom)[0])
      end
    }
    symptoms_and_syndromes_data = {}
    symptom_messages = get_symptoms_messages
    if symptom_messages.any?
      symptoms_and_syndromes_data[:symptom_messages] = symptom_messages
    end
    top_3 = get_top_3_syndromes
    if top_3.any?
      if user.group_id
        group = Group.where("id = ?", user.group_id).first
        group_manager = GroupManager.where("id = ?", group.group_manager_id).first
      end
      symptoms_and_syndromes_data[:top_3] = top_3.map do |obj|
        if user.group_id and user.is_vigilance == true and group_manager[:vigilance_syndromes] != ""
          group_manager[:vigilance_syndromes].each do |vs|
            if vs[:syndrome_id] == obj[:syndrome].id
              self.update_attribute(:syndrome_id, vs[:syndrome_id])
              if vs[:surto_id]  && self.household_id == nil
                report_go_data(group_manager, vs) 
              end
              VigilanceMailer.vigilance_email(self, user, obj[:syndrome]).deliver
            end
          end
        end
        
        { name: obj[:syndrome].description, percentage: obj[:likelyhood] }
      end

      syndrome_message = top_3[0][:syndrome].message
      if !syndrome_message.nil?
        symptoms_and_syndromes_data[:top_syndrome_message] = syndrome_message || ''
      end
    end

    return symptoms_and_syndromes_data
  end

  scope :filter_by_user, ->(user) { where(user_id: user) }

  # Data that gets sent as fields for elastic indexes
  def search_data
    # Set current user/household in variable user
    user = nil
    if !self.household_id.nil?
      user = Household.find(self.household_id)
    else
      user = self.user
    end

    # Get object data as hash off of json
    elastic_data = self.as_json(except: [:updated_at]) 
    
    # Add user group. If group is not present and school unit is, add school unit description
    if !user.group.nil?
      elastic_data[:group] = user.group.get_path(string_only=true, labeled=false).join('/') 
    else
      elastic_data[:group] = nil 
    end
    
    # Add symptoms by column of booleans
    Symptom.all.each do |symptom|
      elastic_data[symptom.description] = self.symptom.include? symptom.description
    end
    
    # Add user's city, state, country, 
    # birthdate, if she is part of the risk group for COVID,
    # race, gender
    elastic_data["gender"] = user.gender 
    elastic_data["race"] = user.race 
    elastic_data["user_city"] = user.class == User ? user.city : nil
    elastic_data["user_state"] = user.class == User ? user.state : nil
    elastic_data["user_country"] = user.country
    elastic_data["birthdate"] = user.birthdate
    elastic_data["risk_group"] = user.risk_group || false
    
    return elastic_data 
  end

  def report_go_data(group_manager, vigilance_syndrome)
    # logging in go data api
    begin 
      crypt = ActiveSupport::MessageEncryptor.new(ENV['GODATA_KEY'])
      password_godata = crypt.decrypt_and_verify(group_manager.password_godata)
    rescue
    end
    uri = URI("#{ENV['GODATA_URL']}/api/oauth/token")
    res = HTTParty.post(uri, body: { username: group_manager.username_godata, password: password_godata })
    if (res.code != 200)
      return
    end
    token = JSON.parse(res.body.gsub('=>', ':'))['access_token']


    # check if case with user already exists
    uri = URI("#{ENV['GODATA_URL']}/api/outbreaks/#{vigilance_syndrome[:surto_id]}/cases/generate-visual-id")
    res = HTTParty.post(uri, body: { 'visualIdMask' => 'GDS_' + self.user.id.to_s }, headers: { Authorization: 'Bearer ' + token})
    if res.code != 409
    #creating case's data
    age = ((Time.zone.now - self.user.birthdate.to_time) / 1.year.seconds).floor
    races = {
      'Branco' => '1',
      'Indígena' => '2',
      'Pardo' => '3',
      'Preto' => '4',
      'Amarelo' => '5'
    }

    symptoms = {
      'Tosse' => '2',
      'Febre' => '3',
      'DorCabeca' => '4',
      'paladareolfato' => '5',
      'Bolhasna Pele' => '6',
      'Calafrios' => '7',
      'Cansaco' => '8',
      'Coceira' => '9',
      'CongestãoNasal' => '10',
      'Diarreia' => '11',
      'DificuldadeParaRespirar' => '12',
      'DorDeEstômago' => '13',
      'DordeGarganta' => '14',
      'DorNasArticulações' => '15',
      'DorNosMúsculos' => '16',
      'DorNosOlhos' => '17',
      'InguaOuGângliosInflamados' => '18',
      'Mal-estar' => '19',
      'ManchasRoxasPeloCorpo' => '20',
      'NáuseaOuVômito' => '21',
      'PeleEOlhosAmarelados' => '22',
      'Sangramento' => '23'
    }

    genders = {
      'Homem Cis' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_MALE',
      'Mulher Trans' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_MALE',
      'Mulher Cis' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_FEMALE',
      'Homem Trans' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_FEMALE',
      'Masculino' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_MALE',
      'Feminino' => 'LNG_REFERENCE_DATA_CATEGORY_GENDER_FEMALE'
    }

    caseData = {
      'firstName' => self.user.user_name.split(" ")[0],
      'gender' => genders[self.user.gender],
      'isDateOfOnsetApproximate' => self.bad_since == nil ? true : false,
      'classification' => "LNG_REFERENCE_DATA_CATEGORY_CASE_CLASSIFICATION_SUSPECT",
      'pregnancyStatus' => 'LNG_REFERENCE_DATA_CATEGORY_PREGNANCY_STATUS_NONE',
      'outbreakId' => vigilance_syndrome[:surto_id],
      'visualId' => "GDS_" + self.user.id.to_s,
      'dob' => self.user.birthdate,
      'age' => {
        'years': age,
      },
      'dateOfReporting' => DateTime.now.in_time_zone('Montevideo'),
      'dateOfOnset' => self.bad_since != nil ? self.bad_since : DateTime.now.in_time_zone('Montevideo')
    }

    
    
    if self.user.group      
      if self.user.group.location_id_godata == nil
          if self.user.group.group_manager_id == 4
              group_location_id = "8101b71b-dbaa-4d3e-b585-459513c1f23a"   
            elsif self.user.group.group_manager_id == 7
              group_location_id = "a3e632e3-3955-4f45-978a-4e835204420c"
          end
        else
          group_location_id = self.user.group.location_id_godata
      end

      caseData['addresses'] = [
            {
              "typeId": "LNG_REFERENCE_DATA_CATEGORY_ADDRESS_TYPE_USUAL_PLACE_OF_RESIDENCE",
              "country": 'Brasil',
              "city": self.user.city,
              "addressLine1": self.user.group.description,
              #"postalCode": '70910-900', #Nao posuimos CEP em nossos cadastros
              "locationId": group_location_id,
              "geoLocationAccurate": false,
              "date": self.created_at,
              "phoneNumber": self.user.phone,
              "emailAddress": self.user.email
            }
          ]
    end

    if self.user.user_name.split(" ").length > 1
      caseData['lastName'] = self.user.user_name.split(" ").last
    end

    # QuestionnaireAnswers
    caseData['questionnaireAnswers'] = {
      'raca_cor' => [
        {
          'value' => races[self.user.race]
        }
      ],
      'profissional_da_saude' => [
        {
          'value' => self.user.is_professional == true ? '1' : '2'
        }
      ],
      'se_foi_ao_hospital' => [
        {
          'value' => self.went_to_hospital != nil ? '1' : '2'
        }
      ],
      'se_saiu_de_casa_nos_ultimos_14_dias' => [
        {
          'value' => self.traveled_to != nil ? '1' : '2'
        }
      ],
      'se_teve_contato_com_alguem_com_os_mesmos_sintomas' => [
        {
          'value' => self.contact_with_symptom != nil ? '1' : '2'
        }
      ],
    }

    # case's symptoms
    if self.symptom.any?
      caseData['questionnaireAnswers']['sintomas'] = [{}]
      caseData['questionnaireAnswers']['sintomas'][0]['value'] = []
      self.symptom.each do |s|
        caseData['questionnaireAnswers']['sintomas'][0]['value'].append(symptoms[s])
      end
    else
      caseData['questionnaireAnswers']['sintomas'] = [{'value': '1'}]
    end

    #Active Outbreak before report case
    uri = URI("#{ENV['GODATA_URL']}/api/users/#{group_manager.userid_godata}")
    res = HTTParty.patch(uri, body: {activeOutbreakId: vigilance_syndrome[:surto_id]}, headers: { Authorization: 'Bearer ' + token})

    #Report case
    uri = URI("#{ENV['GODATA_URL']}/api/outbreaks/#{vigilance_syndrome[:surto_id]}/cases")
    res = HTTParty.post(uri, body: caseData, headers: { Authorization: 'Bearer ' + token})
    end
  end

  def csv_data
    data = self.as_json(except: [ :updated_at, :latitude, :longitude, 
                                  :bad_since, :symptom, :street, :city, 
                                  :state, :country, :deleted_at, :traveled_to, 
                                  :contact_with_symptom, :went_to_hospital]) 
    data[:user_name] = self.user.user_name
    data[:user_created_at] = self.user.created_at
    data[:identification_code] = self.user.identification_code
    data[:household_identification_code] = nil
    data[:household_created_at] = nil
    data[:household_name] = nil
    data[:household_identification_code] = self.household.identification_code if self.household
    data[:household_created_at] = self.household.created_at if self.household
    data[:household_name] = self.household.description if self.household
    data
  end
  
  # this function will not be used anymore, because the offset of
  # the location is not wanted anymore, but it will be here if someone
  # needs one day
  def get_anonymous_latitude_longitude
    # This offsets a survey positioning randomly by, at most, 50 meters, so as to "anonymize" data
    if self.latitude == nil || self.longitude == nil
      return { latitude: nil, longitude: nil }
    end
    
    ret = {}
    dx = 0.05 * rand() # latitude  offset in kilometers (up to 50 meters)
    dy = 0.05 * rand() # longitude offset in kilometers (up to 50 meters)
    r_earth = 6378     # Earth radius in kilometers
    pi = Math::PI

    ret[:latitude]  = self.latitude + (dx / r_earth) * (180.0 / pi)
    ret[:longitude] = self.longitude + (dy / r_earth) * (180.0 / pi) / Math.cos(latitude * pi/180.0)

    ret
  end

  private

  def get_top_3_syndromes
    syndrome_list = []
    syndromes = Syndrome.all
    syndromes.each do |syndrome|
      new_syndrome = {
        syndrome: syndrome,
        likelyhood: get_syndrome_score(syndrome)
      }
      syndrome_list.append(new_syndrome)
    end
    syndrome_list = syndrome_list.sort_by { |syndrome| syndrome[:likelyhood] }.reverse
    syndrome_list = syndrome_list.select { |syndrome| syndrome[:likelyhood] > 0 }
    return syndrome_list[0..2]
  end

  # Calculated with positive predictive value
  # https://en.wikipedia.org/wiki/Positive_and_negative_predictive_values
  def get_syndrome_score(syndrome)
    sum = 0
    modulus_division = 0
    syndrome.symptoms.each do |symptom|
      percentage = SyndromeSymptomPercentage.where(symptom:symptom, syndrome:syndrome)[0]
      if percentage
        if @user_symptoms.include?(symptom)
          sum += percentage.percentage
        end
        modulus_division += percentage.percentage
      end
    end
    if modulus_division == 0
      return 0
    else
      return sum/modulus_division
    end
  end

  def get_symptoms_messages
    messages = []
    @user_symptoms.each do |symptom|
      unless symptom.message.nil?
        messages.append(symptom.message)
      end
    end
    return messages
  end
end
