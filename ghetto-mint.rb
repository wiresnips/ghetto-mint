
require_relative "init"

# if/when there are more banks to pick from, wire a parameter into this puppy and get the right one
require_relative "scrapers/scotiabank"

scraped_entries, account_balances = scrape

# pull the transactions from the timerange on the site
select_saved_entries = "select * from transactions "
unless scraped_entries.empty?
	first, last = scraped_entries.minmax_by{ |e| e.date }.map{ |e| e.date }
	select_saved_entries += "where date >= '#{first}' and date <= '#{last}' "
end

saved_entries = D.query(select_saved_entries, symbolize_keys: true)
saved_entries = saved_entries.map{ |saved| Transaction.new(saved[:account], saved[:date], saved[:label], saved[:amount]) }

# anything that's already in the database we can throw away
saved_entries.each do |saved_entry|
	match = scraped_entries.index saved_entry
	scraped_entries.delete_at match if match
end


# whatever's left is new! shove it into the database
scraped_entries.each do |entry|
	Log << "#{entry.account} #{entry.date} #{entry.amount} #{entry.label}\n"
	D.query "insert into transactions set account='#{D.escape entry.account}', date='#{entry.date}', label='#{D.escape entry.label}', amount=#{entry.amount};"
end

# and then, call the renderer!
require_relative "report"
render_report( account_balances )