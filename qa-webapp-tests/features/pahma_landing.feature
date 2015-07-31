Feature: Checks that PAMHA's dev server's landing page has the correct apps displayed when User signs in and signs out

Scenario: Search for the website
    Given I am on the "pahma" homepage for ""
    Then I will see all available webapps "imagebrowser, imaginator, ireports, search, toolbox, uploadmedia"
    Then sign out
    Then I see "imaginator, search" 