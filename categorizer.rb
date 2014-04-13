


Category_matcher = {
	"groceries" 	=> [ /yig hartman/i, /loblaws/i, /herb.*spice shop/i ],
	"restaurant" 	=> [ /restaurant/i, /coffee/i, /pizza/i, /subway sandwhich/i, /souvlaki/i, /pizza/i ],
	"bar"			=> [ /atomic rooster/i, /fox and feather/i, /quinn/i ],
	"rent"			=> [ /money order purchase/i ],
	"cash"			=> [ /withdrawal/i ],
	"bank fees"		=> [ /service charge/i ],
	"household"		=> [ /ikea/i, /staples/i, /dollar it/i ],
	"entertainment"	=> [ /strategy games/i, /cineplex/i ],
	"alcohol"		=> [ /lcbo/i, /wine rack/i, /beer store/i ]
}

# merge each category's list of regexes, for simpler matching
Category_matcher.each do |category, matchers|
	Category_matcher[category] = Regexp.union matchers
end

def categorize (transaction)
	match = Category_matcher.find{ |category, matcher| transaction[:label] =~ matcher }
	return match ? match.first : "UNCATEGORIZED"
end