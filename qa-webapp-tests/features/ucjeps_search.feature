Feature: the UCJEPS Portal (Search) application

Scenario: Find and use the keyword search feature
    Given I am on the "ucjeps" homepage
    Then I will sign in
    Then I click app "search"
    Then I verify the search fields "Scientific Name, Collector(s), Locality (verbatim), County, Cultivated?, Major Group, Date Collected, Associated Taxa, Type Assertions?, Collection Number, Specimen ID, Country" in "div#searchfieldsTarget"

    When I enter "Arroyo" in the "localityverbatim" field
    Then I click on "Arroyo Calmalli" in the dropdown menu and search
    Then I verify the table headers "Specimen ID, Scientific Name, Collector(s) (verbatim), Collection Number, Date Collected, Locality (verbatim), County, State, Country"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file

    When I click "Maps"
    Then I verify the maps buttons
    When I click the button "map selected with Google staticmaps API"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click the button "map selected with Berkeley Mapper"
    #Then the url contains "http://berkeleymapper.berkeley.edu"

    When I click "Statistics"
    Then I will select "Specimen ID" under Select field to summarize on
    Then I find the content "Specimen ID, Count" in "div#statsresults"
    Then I click the button "downloadstats" and download the csv file

    When I click "Facets"
    Then I find the content "Scientific Name, Major Group, Family, Collector(s), County, State, Country" in "div#tabs"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "C. A. Purpus" and see it appear in the field "collector"
    Then I will click "Reset" and the "collector" field should have ""

    When I enter "UC1624979" in "accession" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I find the content "Current time:" in "div#container"
    When I find the content "About, Help, Credits, Terms" in "div#branding"

    When I click "Help"
    Then I find the content "Some fields have an option of searching as either "keyword", "phrase", or "exact"." in "div#helpTarget"
    When I click "Credits"
    Then I find the content "For questions about the content, and to access content beyond what is provided here, please contact David Baxter, dbaxter@berkeley.edu." in "div#creditsTarget"
    When I click "Terms"
    Then I find the content "Terms of Use" in "div#termsTarget"
    When I go back

    When I click "Sign out"
    Then I see "eloan, publicsearch, search" in "div#content-main"
