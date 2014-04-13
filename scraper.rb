require 'io/console'
require 'mechanize'
require 'logger'
require 'mysql2'

# parse the one and only argument we accept
cookies_only = ARGV.include? "--cookies-only"

# prep the logger
log = Logger.new File.join(__dir__, "log/scraper.log") rescue nil
log << Time.new
log << "\n"

# prep the scraper
agent = Mechanize.new
agent.log = log
agent.user_agent_alias = "Windows IE 9"
agent.cookie_jar.load File.join(__dir__, '.cookies') rescue nil 


# go fetch the page!
page = agent.get "https://www1.scotiaonline.scotiabank.com/online/authentication/authentication.bns"

# if we aren't signed in, we gotta do that
if page.uri.to_s.include? "authentication"
	# bail if there's no human
	log << "Human input needed to proceed\n" and exit if cookies_only

	# get username and password from the human, pump them through to the form
	login = page.form "signon_form"
	
	print "user:"
	login["signon_form:userName"] = STDIN.noecho(&:gets).chomp
	puts

	print "pass:"
	login["signon_form:password_0"] = STDIN.noecho(&:gets).chomp 
	puts

	page = agent.submit login, login.buttons.first

	# have we been punted to a secret question?
	while page.uri.to_s.include? "mfaAuthentication"
		form = page.form "mfaAuth_form"
		form.radiobutton_with(id: "mfaAuth_form:register:0").check

		print "secret question: " + page.search("table//td")[0].content
		form["mfaAuth_form:answer_0"] = STDIN.noecho(&:gets).chomp 
		puts

		page = agent.submit form, form.buttons.first
	end
end


# update our cookies, just in case there's something useful in there
agent.cookie_jar.save_as File.join(__dir__, '.cookies'), session: true, format: :yaml	

def url_params (url)
	Hash[ url.split("?").last.split("&").map{ |param| param.split("=") } ]
end

# from the homepage, grab the list of accounts
bank_account_links = page.search "table[@summary='Banking accounts']//td/a"
cred_account_links = page.search "table[@summary='Borrowing accounts']//td/a"

scraped_entries = []

# cycle through them and read in everything they've got
bank_account_links.each do |link|
	page = agent.get link[:href]
	account = url_params(link[:href])['acctId']

	transaction_rows = page.search "//form[@id = 'table_form']//table/tbody/tr" 
	next unless transaction_rows
	
	transaction_rows.each do |row|
		row.css('br').each{ |br| br.replace "\n" }

		date     = row.element_children[0].content.strip
		label    = row.element_children[1].content.strip
		withdraw = BigDecimal.new row.element_children[2].content.gsub(',','').strip
		deposit  = BigDecimal.new row.element_children[3].content.gsub(',','').strip

		date = Date.parse date
		label = label.strip.gsub(/\s+/, ' ')
		amount = deposit - withdraw

		scraped_entries << { account: account, date: date, label: label, amount: amount }
	end
end


cred_account_links.each do |link|
	page = agent.get link[:href]
	account = url_params(link[:href])['acctId']

	transaction_rows = page.search "//form[@id = 'history_table_form']//table/tbody/tr[not(@class)]"
	next unless transaction_rows

	transaction_rows.each do |row|
		row.css('br').each{ |br| br.replace "\n" }

		date     = row.element_children[0].content.strip
		label    = row.element_children[2].content.strip
		withdraw = BigDecimal.new row.element_children[3].content.gsub(',','').strip
		deposit  = BigDecimal.new row.element_children[4].content.gsub(',','').strip

		date = Date.parse date
		label = label.strip.gsub(/\s+/, ' ')
		amount = deposit - withdraw

		scraped_entries << { account: account, date: date, label: label, amount: amount }
	end
end


# create the table if it doesn't exist yet
D = Mysql2::Client.new username: "root"
D.query "create database if not exists finance;"
D.query "use finance;"
D.query "create table if not exists transactions( account varchar(255), date date, label varchar(255), amount decimal(10, 2) );"


# pull the transactions from the timerange on the site
select_saved_entries = "select * from transactions "
unless scraped_entries.empty?
	first, last = scraped_entries.minmax_by{ |e| e[:date] }.map{ |e| e[:date] }
	select_saved_entries += "where date >= '#{first}' and date <= '#{last}' "
end

saved_entries = D.query(select_saved_entries, symbolize_keys: true)

# anything that's already in the database we can throw away
saved_entries.each do |saved|
	match = scraped_entries.index{ |scraped| scraped.keys.all?{ |key| scraped[key] == saved[key] } }
	scraped_entries.delete_at match if match
end

exit if scraped_entries.empty?

# whatever's left is new! shove it into the database
scraped_entries.each do |entry|
	log << "#{entry[:account]} #{entry[:date]} #{entry[:amount]} #{entry[:label]}\n"

	entry[:account] = D.escape entry[:account]
	entry[:label] = D.escape entry[:label]
	D.query "insert into transactions set account='#{entry[:account]}', date='#{entry[:date]}', label='#{entry[:label]}', amount=#{entry[:amount]};"
end




month_ago = Time.now - (30 * 60 * 60 * 24)
transactions = D.query "select * from transactions where date >= '#{ month_ago }'", symbolize_keys: true

# categorize them
require_relative "categorizer"

totals = {}
totals.default = 0

transactions.each do |transaction|
	category = categorize transaction
	totals[category] += transaction[:amount]
end

# crude, but effective -put some thought into filtration vs categorization
totals = totals.to_a
totals.reject!{ |total| total[0] == "UNCATEGORIZED" }
totals.sort_by!{ |total| total[1].abs }.reverse!



# look, whatever - we can get a real templating engine later

File.open("report/index.html", "w") do |html|
	html << "<!DOCTYPE html>\n<html>\n<head>\n"
	html << "\t<title>report</title>\n\t<link rel='stylesheet' href='style.css'>\n</head>\n"
	html << "<body>\n\n"

	# okay, now let's try to get a LITTLE fancier
	graph_max = (totals[0][1].abs / 50).ceil * 50

	html << "\t<table>\n"
	totals.each do |category, total| 
		html << "\t\t<tr>\n"
		html << "\t\t\t<td>#{category}</td>\n"
		html << "\t\t\t<td class='bar'><div style='width:#{ (total.abs * 100 / graph_max).to_f }%;'></div></td>\n"
		html << "\t\t\t<td>#{ sprintf "%.2f", total.abs }</td>\n"
		html << "\t\t</tr>\n"
	end
	html << "\t</table>\n"
	html << "\n\n</body>\n</html>\n"
end

