
require 'logger'
require 'mysql2'

# let's establish some basic universal stuff to work against

# where the hell are we?
DIR = File.dirname(File.realpath(__FILE__))

# here's our basic data structure
Transaction = Struct.new(:account, :date, :label, :amount, :category)


# prep the logger
Log = Logger.new File.join(DIR, "log/ghetto-mint.log") rescue nil
Log ||= Logger.new STDOUT
Log << "#{Time.new}\n"


# create the table if it doesn't exist yet
D = Mysql2::Client.new username: "root"

D.query "create database if not exists finance;"
D.query "use finance;"

D.query "create table if not exists accounts( id int not null auto_increment, name varchar(255), balance decimal(10,2) not null default 0.00, primary key (id) );"
D.query "create table if not exists transactions( account_id int, date date, label varchar(255), amount decimal(10, 2), foreign key (account_id) references accounts(id) );"
