Feature: the UCJEPS PublicSearch application

Scenario: Find and use the publicsearch feature, including making queries, verifying results and table headers, clicking buttons and tabs, downloading csv files, and logging out.
    Given I am on the "ucjeps" homepage
    Then I will sign in
    Then I check for "usericon.jpg"
    Then I click app "publicsearch"

    #Then I mark the checkboxes "typesonly, cultivated"
    Then I find the content "Current time:" in "div#container"
    When I enter "mint" in "keyword" and click "List"
    Then I mark the checkboxes "item-0"
    Then I verify the table headers "Specimen ID, Scientific Name, Collector(s) (verbatim), Date Collected, Collection Number, County, State, Country, Locality (verbatim)"
    Then I find the content "100" in "select#maxresults"
    Then I click the button "download selected as csv" and download the csv file

    When I click "Maps"
    Then I verify the maps buttons
    When I click the button "map selected with Google staticmaps API"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click the button "map selected with Berkeley Mapper"
    #Then the url contains "http://berkeleymapper.berkeley.edu"

    When I click "Facets"
    Then I find the content "determination, majorgroup, collector, county, state, country" in "div#tabs"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Arenaria macradenia S. Watson var. macradenia" and see it appear in the field "determination"
    Then I will click "Reset" and the "keyword" field should have ""