require 'rufus-scheduler'
require 'mail'
require 'faraday'

Mail.defaults do
  delivery_method :smtp, 
  address:        "smtp.gmail.com",
  port:           587,
  domain:         "localhost",
  authentication: "plain",
  user_name:      "ror.test.e@gmail.com",
  password:       "ror123456789",
  enable_starttls_auto: true
end

site1 = 'https://pokupon.ua/'
site2 = 'https://partner.pokupon.ua/'
sites = [site1, site2]

scheduler = Rufus::Scheduler.new

scheduler.every '1m' do
  sites.each do |site|
	path = "#{Dir.pwd}/status#{sites.index(site)}.txt"
	old_status = File.read(path).chomp
	response = Faraday.get site
	File.open(path, 'w') { |file| file.write("#{response.status}") }

	if response.status.to_s != old_status
		if response.status != 200
			Mail.deliver do
			  from    'ror.test.e@gmail.com'
			  to      'alert@pokupon.ua'
			  subject "Error when requesting the site - #{site}"
			  body    "Response status - #{response.status}."
			end
		elsif response.status == 200
			Mail.deliver do
			  from    'ror.test.e@gmail.com'
			  to      'alert@pokupon.ua'
			  subject "Access resumed to site - #{site}"
			  body    "Response status - #{response.status}."
			end
		end
	end
  end
end

scheduler.join