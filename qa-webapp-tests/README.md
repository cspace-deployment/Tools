# CSpaceAutomatedTesting

This repository is for automated files written in Gherkin and Ruby with the Capybara library, Selenium driver, and other gems (e.g. rspec, capybara-screenshot).

## I. Setting Up
To get started, install the latest versions of Ruby:

1) Install Ruby using the [Ruby Version Manager](https://rvm.io/rvm/install)
```ruby
\curl -L https://get.rvm.io | bash -s stable --ruby
```

2) Install gems
```bash
bundle update
bundle install
```

* Install [Firefox](https://www.mozilla.org/en-US/firefox/new/), the web browser used to run the tests.

3) Fork and clone this repository to your local directory

4) Initialize the environment variables
* In Tools/qa-webapp-tests/config create an environments.yml file using the format of sample_environments.yml.
* In Tools/qa-webapp-tests/config/environments.yml:
    - Set 'login' and 'password' to your user credentials but omitting the @xxx.xxx for 'login' (e.g. if the login is sample@cspace.berkeley.edu, set 'login': sample)
    - Set the 'server' variable to "" for prod or "-dev" for dev

6) Run the tests

In the qa-webapp-tests directory 

Run all test cases:
```bash
cucumber
```

To run a particular test

```bash
cucumber features/[featurename].feature
```

The results are in this format:

```
> 1 scenario (1 passed)
> 10 steps (10 passed)
> 0m7.492s
```

## II. Repo Structure
Here is a brief overview of the repository structure:

```ruby
qa-webapp-tests
    >> features
        *location of all feature files*
        >> step_definitions
            *location of all step definition Ruby files*
        >> support
            *location of configuration files, e.g. env.rb*
```     

Features describe the frontend components that users interact with. 
Step definitions describe the user actions for each step. Multiple step definitions make up a feature.

## III. About the Tools

[Capybara](http://jnicklas.github.io/capybara/) is a library written in Ruby that simulates how a user would interact with an app. 

[Cucumber](http://cukes.info) is a tool that interprets plain-text descriptions as automated tests and allows testers to write tests in human-readable format. Cucumber scripts are parsed by Gherkin into scenarios. These scenarios contain steps that are matched to the step definitions written in Ruby. 

(Source: https://girliemangalo.wordpress.com/2012/10/29/introduction-to-cucumber/)

## IV. Using Chrome instead of Firefox

To change the default browser selenium runs from Firefox to Chrome, first download chromedriver using either homebrew 
```bash
brew install chromedriver
```
or through their [website](https://sites.google.com/a/chromium.org/chromedriver/).

Then, for the feature you want to run with chrome, add a @javascript tag in the line before Scenario. For example, if we want to use chrome for features/pahma_search.feature, inside we add:
```
Feature: Find and use the keyword search feature of the PAHMA development server.

@javascript
Scenario: Test a webapp
```
