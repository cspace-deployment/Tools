Feature: The BAMPFA imagebrowser

Scenario: Find and use the imagebrowser feature, including making searches, verifying headers, downloading .csv files, and clicking tabs.
    Given I am on the "bampfa" homepage
    Then I will sign in
    Then I click the link with text "imagebrowser"
    When I search for "wolf" in "keyword" and enter "10"
    Then I click the link with text "1995.46.437.48"
    Then I find the content "keywords, maximum number of objects to retrieve" in "div#content"
