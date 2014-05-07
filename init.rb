
require 'logger'
require 'mysql2'

# let's establish some basic universal stuff to work against

# where the hell are we?
DIR = File.dirname(File.realpath(__FILE__))

# here's our basic data structure
Transaction = Struct.new(:account, :date, :label, :amount, :category)


# prep the logger
Log = Logger.new "#{DIR}/log/ghetto-mint.log" rescue nil
Log ||= Logger.new STDOUT
Log << "\n\n#{Time.new}\n"


# create the table if it doesn't exist yet
D = Mysql2::Client.new username: "root"

D.query "create database if not exists finance;"
D.query "use finance;"

D.query "create table if not exists transactions( account varchar(255), date date, label varchar(255), amount decimal(10, 2) );"
