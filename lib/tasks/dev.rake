namespace :dev do
  desc "TODO"
  task setup: :environment do
    puts "Configuring Development environment"

    show_spinner("Dropping db...") do 
      %x(rails db:drop)
    end
    
    show_spinner("Creating db...") do 
      %x(rails db:create)
    end
    
    show_spinner("Migrating db...") do 
      %x(rails db:migrate)
    end

    show_spinner("Creating Apps...") do
      1..20.times do
        App.create!(
          app_name: Faker::Company.name,
          owner_country: Faker::Address.country
        )
      end
    end

    show_spinner("Creating admins...") do
      App.all.each do |app|
        2.times do
          Admin.create!(
            email: Faker::Internet.email,
            password: "12345678",
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            is_god: [true, false].sample,
            app_id: 1
          )
        end
        Manager.create!(
          email: Faker::Internet.email,
          password: "12345678",
          first_name: Faker::Name.first_name
          app_id: 1
        )
      end
    end

    show_spinner("Creating 100 example users...") do
      100.times do |i|
        User.create!(
            user_name: Faker::Name.name,
            email: Faker::Internet.email,
            password: "12345678",
            birthdate: Faker::Date.birthday(18, 65),
            country: Faker::Address.country,
            gender: Faker::Gender.type,
            race: "human",
            is_professional: false,
            app: App.all.first
        )
      end
    end

    show_spinner("Inserting Kinships on created users...") do
      kinships = ["Pai", "Mãe", "Filho", "Conjuge"]
    
      User.all.each do |user|
        3.times do
          Household.create!(
            description: Faker::Name.name,
            birthdate: Faker::Date.birthday(18, 65),
            country: Faker::Address.country,
            gender: ["male", "female"].sample,
            race: "human",
            kinship: kinships.sample,
            user_id: user.id
          )
        end
      end
    end
     
  
    show_spinner("Creating 10 example content...") do
      10.times do |j|
        Content.create!(
          title: Faker::Movies::LordOfTheRings.character,
          content_type: Faker::Music.genre,
          body: Faker::Lorem.paragraph([1,2,3,4].sample, false, [1,2,3,4].sample),
          app_id: App.all.sample.id
      )
      end
    end

    show_spinner("Creating 10 symptoms...") do
      App.all.each do |a|
        10.times do |j|
          Symptom.create!(
            description: Faker::Name.name,
            code: Faker::Number.number,
            priority: rand(0..10),
            details: Faker::Quotes::Shakespeare.as_you_like_it_quote,
            app_id: a.id
          )
        end
      end
    end
  
    show_spinner("Creating 50 example Public Hospitals...") do
      50.times do |k|
        PublicHospital.create!(
          description:Faker::Company.name,
          latitude: Faker::Address.latitude ,
          longitude: Faker::Address.longitude,
          kind: Faker::Movies::StarWars.character,
          phone: Faker::PhoneNumber.phone_number,
          details: Faker::Lorem.paragraph([1,2].sample, false, [1,2].sample),
          app_id: App.all.sample.id 
      )
      end
    end

    show_spinner("Create some surveys") do
      symptom_arr = []
      Symptom.all.each do |s|
        symptom_arr.append(s.description)
      end
  
      User.all.each do |user|
        3.times do
          symptom_can = [nil, symptom_arr]
  
          Survey.create!(
            latitude: 40.741934119747704,
            longitude: -73.98951017150449,
            symptom: symptom_can.sample,
            user_id: user.id,
          )
        end
      end
    end
  end

  task create_prod: :environment do
    if Rails.env.production?
      show_spinner("Criando Aplicativo do Brasil...") do 
        App.create(
          owner_country: "Brasil",
          app_name: "Guardiões da Saúde"
        )
      end

      2.times do 
        Survey.create!(
          latitude: 40.741934119747704,
          longitude: -73.98951017150449,
          symptom: symptom_arr,
          user_id: u.id,
        )
      end
    end
  end

  def show_spinner(start_msg, end_msg = "done")
    pastel = Pastel.new

    format = "[#{pastel.yellow(':spinner')}] " + pastel.yellow("#{start_msg}")
    
    spinner = TTY::Spinner.new(format, success_mark: pastel.green('+'))
    spinner.auto_spin
    
    yield
    spinner.success(pastel.green("#{end_msg}"))
  end
end