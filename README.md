Dumb-as-bricks financial tracking
=================================

Scrape your bank's website, shove your transaction history into a local database, render a breakdown into static html to serve on your home network (or whatever). I built ghetto-mint for myself because I wanted basic financial analytics, but I didn't want to have to trust Mint with my bank login.

Some Assembly Required
======================

With that in mind, ghetto-mint is about as dumb as it could possibly be. The whole thing is less than 250 lines of ruby. The hope is that anyone comfortable with the language will be able to read the code and be confident that it isn't doing anything sneaky. Then they could retrofit the scraper code for their own financial institution and run their own financial analytics.

This is not a packaged solution, and it probably won't work out of the box. It's more like a *template* of a program than anything else.

Setup
=====

If you want to get this working for yourself, here's what you need:

* mysql
* ruby
* the mechanize and mysql2 gems

to do: full set up & installation on a fresh system (pref ubuntu)
