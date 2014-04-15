Dumb-as-bricks financial tracking
=================================

Scrape your bank's website, shove your transaction history into a local database, render a breakdown into static html to serve on your home network (or whatever). I built ghetto-mint for myself because I wanted basic financial analytics, but I didn't want to have to trust Mint with my bank login.

Some Assembly Required
======================

With that in mind, ghetto-mint is about as dumb as it could possibly be. The whole thing is less than 250 lines of ruby. The hope is that anyone comfortable with the language will be able to read the code and be confident that it isn't doing anything sneaky. Then they could retrofit the scraper code for their own financial institution and run their own financial analytics.

This is not a packaged solution, and it probably won't work out of the box. It's more like a *template* of a program than anything else.

Setup
=====

This is the bare minimum to get to a working setup on a totally fresh ubuntu system (12.04). The details and gotchas will probably vary from distro to distro. If you get things up and running on another OS, I'd love to hear the blow-by-blow, and post another guide.

```bash
$ sudo apt-get update
$ sudo apt-get install ruby1.9.1-dev build-essential mysql-server libmysqlclient-dev
$ sudo gem install mechanize mysql2
```

* ghetto-mint is not especially picky about the version of ruby, but you *do* want the '-dev' edition of whatever you take- the gems rely on it.
* MySQL will want you to enter a root password. It'll be rather insistent about it, actually. If you create one instead of leaving it blank, you will need to let scraper.rb know what it is. Look for

    ```ruby
    D = Mysql2::Client.new username: "root"
    ```
    and update it to
    ```ruby
    D = Mysql2::Client.new username: "root", password: "your-mysql-password"
    ```

Once that's all done, download ghetto-mint and unzip it somewhere. I'm going to assume for the rest of this guide that you put it in ```~/Downloads```. Head over there and give it a whirl.

A note for the paranoid: it's distinctly possible that if you've gotten this far, you're about to run my code and tell it how to sign into your bank. This would be a good time to inspect it (there really isn't all that much of it) and satisfy yourself that it's innocent.

```bash
$ cd ~/Downloads/ghetto-mint-master
$ ruby scraper.rb
```

If everything went properly, you'll be prompted for your scotiabank login info. When you type, nothing will appear in the console. This is normal. If everything continues to go properly, it'll spew output all over your console (to prevent this, create a log/ folder before hand), including whatever transactions are currently visible in each of your accounts.

Next, we'll fire up a simple web-server and have a look at the report.

```bash
$ cd report
$ ruby -run -e httpd . -p 5000
```

Pop open a web browser and visit ```localhost:5000``` - you should see a simplistic breakdown of your last transactions. Anything that didn't fit a category is simply ignored. You'll almost certainly need to modify categorizer.rb to conform to your spending habits.

For the final trick, we'll set up a couple of cron jobs to keep everything up to date.

```bash
$ crontab -e
```

Add the following lines- it'll hit your bank site every eight minutes and start the report's server on startup.

```
# update ghetto-mint before the cookies go stale
*/8 * * * * ruby /home/user-name/Downloads/ghetto-mint-master/scraper.rb --cookies-only

# launch ghetto-mint's report server on startup
@reboot cd /home/user-name/Downloads/ghetto-mint-master/report && ruby -run -e httpd . -p 5000
```

Remember to modify the paths to match wherever you actually put ghetto-mint. The --cookies-only flag causes ghetto-mint to give up if it finds a login screen, instead of waiting around for user input - it'll only succeed if it's cookies can get it in.
