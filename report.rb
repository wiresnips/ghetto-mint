require 'haml'
require 'date'
require_relative "init"

def render_report (balances)
	days_to_count = 60

	# pull up the last couple weeks of transactions
	startingpoint = (Date.today - days_to_count)
	raw_transactions = D.query "select * from transactions where date >= '#{ startingpoint }'", symbolize_keys: true

	# categorize them
	require_relative "categorizer"
	transactions = raw_transactions.map{ |raw| Transaction.new(raw[:account], raw[:date], raw[:label], raw[:amount], categorize(raw[:label]) ) }
	



	# from the current balance and transaction history, reconstruct the closing balance each day
	balance_history = {}
	accounts = transactions.map(&:account).uniq
	accounts.each{ |account| balance_history[account] = [balances[account]] }

	(startingpoint..Date.today).to_a.reverse.each do |day|
		day_transactions = transactions.select{ |t| t.date == day }

		accounts.each do |account|
			net = day_transactions.select{|t| t.account == account}.map(&:amount).inject(:+)
			net ||= 0
			balance_history[account] << balance_history[account].last - net
		end
	end

	balance_history.keys.each{ |account| balance_history[account].reverse! and balance_history[account].pop }



	# okay, let's get the average category spending per day
	cat_avg_day = transactions.group_by(&:category).to_a.map{ |cat, trans| [cat, trans.map(&:amount).inject(:+) / days_to_count] }
	cat_avg_day.map!{|cat, avg| [cat, avg * -1]}.reject!{ |cat, avg| avg < 1 }
	cat_avg_day.sort_by!{ |cat, avg| avg }




	view_values = {
		period: (startingpoint..Date.today),
		transactions: transactions,
		balances: balance_history,
		cat_avg_day: cat_avg_day
	}


	File.open("#{DIR}/report/index.html", "w") do |file|
		engine = Haml::Engine.new(File.read( File.join(DIR, "index.html.haml")))
		file << engine.render( Object.new, view_values )
	end

end
