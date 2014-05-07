
Category_matcher = {
	"salary"        => [ /payroll/i ],
	"groceries"     => [ /loblaws/i ],
	"restaurant"    => [ /restaurant/i, /coffee/i, /pizza/i, /subway/i, /souvlaki/i, /tim horton/i, 
                             /shawarma/i, /greco/i, /thai/i, /burger/i, /diner/i  ],
	"bar"           => [ /royal oak/i, /brew pub/i, /irish pub/i ],
	"rent"          => [ /money order purchase/i ],
	"cash"          => [ /withdrawal/i ],
	"bank fees"     => [ /service charge/i ],
	"household"     => [ /ikea/i, /staples/i, /wal-mart/i, /amazon/i, /target/i ],
	"entertainment" => [ /cineplex/i, /humblebundle/i ],
	"alcohol"       => [ /wine rack/i, /beer store/i ],
	"utilities"     => [ /hydro/i ],
	"other bills"   => [ /name-cheap/i, /github/i ],
	"transfer"      => [ /customer transfer/i, /mb-credit card/i ]
}

# merge each category's list of regexes, for simpler matching
Category_matcher.each do |category, matchers|
	Category_matcher[category] = Regexp.union matchers
end

def categorize (label)
	match = Category_matcher.find{ |category, matcher| label =~ matcher }
	return match ? match.first : "uncategorized"
end
