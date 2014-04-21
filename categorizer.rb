
Category_matcher = {
	"salary"		=> [ /payroll/i ],
	"groceries" 	=> [ /yig hartman/i, /loblaws/i, /herb.*spice shop/i, /quickie/i, /korean market/i ],
	"restaurant" 	=> [ /restaurant/i, /coffee/i, /pizza/i, /subway/i, /souvlaki/i, /tim horton/i, 
						 /saigon pho/i, /shawarma/i, /greco/i, /thai/i, /burger/i, /stone face dolly/i ,
						 /kasbah village morocca/i, /diner/i,  ],
	"bar"			=> [ /atomic rooster/i, /fox and feather/i, /quinn/i, /royal oak/i, /brew pub/i,
						 /pub italia/i, /irish pub/i, /hooley/i, /sir john a/i ],
	"rent"			=> [ /money order purchase/i ],
	"cash"			=> [ /withdrawal/i ],
	"bank fees"		=> [ /service charge/i ],
	"household"		=> [ /ikea/i, /staples/i, /dollar it/i, /wal-mart/i, /amazon/i, /target/i ],
	"entertainment"	=> [ /strategy games/i, /cineplex/i, /humblebundle/i ],
	"alcohol"		=> [ /lcbo/i, /wine rack/i, /beer store/i ],
	"utilities"		=> [ /hydro/i, /tsi internet/i, /virgin mobile/i ],
	"other bills"	=> [ /name-cheap/i, /github/i, /peggy roman/i ],
	"transfer"		=> [ /customer transfer/i, /mb-credit card/i ]
}

# merge each category's list of regexes, for simpler matching
Category_matcher.each do |category, matchers|
	Category_matcher[category] = Regexp.union matchers
end

def categorize (label)
	match = Category_matcher.find{ |category, matcher| label =~ matcher }
	return match ? match.first : "uncategorized"
end