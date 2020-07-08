Feature: The PAHMA imaginator application

Scenario: Test the Imaginator by checking queries made with "Search the Metadata" and "Search for Images".
    Given I am on the "pahma" homepage
    Then I will sign in
    Then I click "imaginator"
    Then I will enter "keyword" "augustus" in the "Search the Metadata" field
    Then I click "2-13166"
    Then I find the content "LatLong, Object Type,  Context of Use, Dimensions, Comment, Collection Date" in "div#content"
    Then I will enter "keyword" "seed beater" in the "Search for Images" field
    Then I click "1-730"
    Then I find the content "Seed beater" in "div#content"
    When I click "Sign out"
    Then I see "search" in "div#content-main"