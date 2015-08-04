require 'rubygems'
require 'selenium-webdriver'
require 'capybara'
require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'

require File.expand_path('../custom_config', __FILE__)
include CustomConfig
Capybara.default_driver = :selenium
Capybara.default_wait_time = 15

# To override default settings in the capybara-screenshot gem: 
Capybara.save_and_open_page_path = "tmp/capybara"
# To keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

#########################################################################################
# Uncomment the code below to run tests without a browser window. 
# This uses the selenium webdriver with headless gem
# Note that this only works for Linux machines due to X graphics.
# More info at README.md 
#########################################################################################
# if Capybara.current_driver == :selenium
#   require 'headless'
#   headless = Headless.new
#   headless.start
# end


#########################################################################################
# Uncomment the code below to run tests without a browser window.
# This uses the poltergeist webdriver
# This works on OS X and on Linux.
# More info at README.md 
#########################################################################################
# require 'capybara/poltergeist'
# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, :timeout => 45)
# end

# Capybara.default_driver = :poltergeist


#########################################################################################
# Uncomment the code below to run tests without a browser window. 
# This uses the capybara-webkit. It requires changing some of the test
# suites. Only use this if you cannot run either headless or 
# poltergeist and wish to run tests without browser window.
# This works on OS X and on Linux.
# More info at README.md 
#########################################################################################  
# require 'capybara-webkit'
# Capybara::Webkit.configure do |config|
# 	config.allow_unknown_urls
# 	config.timeout = 45
# end
# Capybara.default_driver = :webkit


##########################################################################
# Uncomment the code below to run tests on chrome. More info at README.md
##########################################################################
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end

# Capybara.javascript_driver = :chrome

World(Capybara)