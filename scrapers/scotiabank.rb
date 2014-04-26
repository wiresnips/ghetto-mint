
require 'mechanize'
require 'io/console'
require_relative "../init"


# parse the one and only argument we accept
COOKIES_ONLY = ARGV.include? "--cookies-only"

def scrape 

	# prep the scraper
	agent = Mechanize.new
	agent.log = Log
	agent.user_agent_alias = "Windows IE 9"
	agent.cookie_jar.load "#{DIR}/.cookies" rescue nil 

	# go fetch the page!
	page = agent.get "https://www1.scotiaonline.scotiabank.com/online/authentication/authentication.bns"

	# if we aren't signed in, we gotta do that
	if page.uri.to_s.include? "authentication"

		# bail if there's no human
		Log << "Human input needed to proceed\n" and exit if COOKIES_ONLY

		# get username and password from the human, pump them through to the form
		login = page.form "signon_form"
		
		print "user:"
		login["signon_form:userName"] = STDIN.noecho(&:gets).chomp
		puts

		print "pass:"
		login["signon_form:password_0"] = STDIN.noecho(&:gets).chomp 
		puts

		# submit the user's login info
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
	agent.cookie_jar.save_as File.join(DIR, '.cookies'), session: true, format: :yaml	

	transactions = []
	balances = {}

	# from the homepage, grab the list of accounts
	bank_account_links = page.search "table[@summary='Banking accounts']//td/a"
	cred_account_links = page.search "table[@summary='Borrowing accounts']//td/a"

	# cycle through them and read in everything they've got
	bank_account_links.each do |link|
		page = agent.get link[:href]
		account = url_params(link[:href])['acctId']
		balances[account] = page.search("//form[@id = 'accountDet']//div[span/text() = 'Available balance:']").first.text.gsub(/[^0-9\.]/, '').to_f

		transaction_rows = page.search "//form[@id = 'table_form']//table/tbody/tr" 
		next unless transaction_rows
		
		transaction_rows.each do |row|
			row.css('br').each{ |br| br.replace "\n" }

			date     = row.element_children[0].content.strip
			label    = row.element_children[1].content.strip
			withdraw = BigDecimal.new row.element_children[2].content.gsub(',','').strip
			deposit  = BigDecimal.new row.element_children[3].content.gsub(',','').strip
			balance  = BigDecimal.new row.element_children[4].content.gsub(',','').strip

			date = Date.parse date
			label = label.strip.gsub(/\s+/, ' ')
			amount = deposit - withdraw

			transactions << Transaction.new(account, date, label, amount)
		end
	end


	cred_account_links.each do |link|
		page = agent.get link[:href]
		account = url_params(link[:href])['acctId']
		balances[account] = page.search("//form[@id = 'ft_form']//div[contains(@class,'bal-owing')]").first.text.gsub(/[^0-9\.]/, '').to_f * -1

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

			transactions << Transaction.new(account, date, label, amount)
		end
	end

	return transactions, balances
end


def url_params (url)
	Hash[ url.split("?").last.split("&").map{ |param| param.split("=") } ]
end
