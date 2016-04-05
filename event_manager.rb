require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  # if zipcode.nil? 
  #   zipcode = "00000"
  # elsif zipcode.length < 5
  #   zipcode = zipcode.rjust(5, "0")
  # elsif zipcode.length > 5
  #   zipcode = zipcode[0..4]
  # else
  #   zipcode
  # end

  # Above code can be rewritten as below
  # nil.to_s = ""
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
  phone = phone.scan(/[0-9]/).join
  if phone.length == 11 && phone[0] == "1"
    phone = phone[1..10]
  end
  phone
end

def valid_phone?(phone)
  phone = clean_phone(phone)
  return phone.length == 10 ? true : false
end

def legislators_by_zipcode(zipcode)
  legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

def print_registration_date(registration_dates)
  hours = []
  days_week = []

  registration_dates.each do |date| 
    date = DateTime.strptime(date, "%m/%d/%y %H:%M")
    hours << date.hour
    days_week << date.wday
  end

  # Group every hour
  hours = hours.group_by { |i| i }
  puts " Hour  Registrations"
  hours.each { |index,i| puts "#{index}:00       #{i.count}" }

  puts ""

  # Group day of the week
  days_week = days_week.group_by { |i| i }
  puts "Day of the week  Registrations"
  days_week.each { |index, i| puts "    #{index}                  #{i.count}" }
  
end

puts "EventManager initialized."

content = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
registration_dates = []

content.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)

  # Iteration: Clean phone numbers
  puts valid_phone?(row[:homephone])

  registration_dates << row[:regdate]

end

# Iteration : Time targeting and Iteration: Day of the week targeting
# Print the list of registrations per hour and day of the week.
# With this list we can order descendent, select peak hours, etc
print_registration_date(registration_dates)


