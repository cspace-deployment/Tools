Feature: UCJEPS landing page

Scenario: Checks that the landing page has the correct apps displayed when User signs in and signs out
    Given I am on the "ucjeps" homepage
    Then I find the content "Applications Available" in "div#content-main"
    Then I find the content "to view all available applications" in "div#content"
    When I click "Sign in"
    Then I find the content "Sign in to the CollectionSpace Webapps using the same login and password you use to login to the CollectionSpace system itself." in "div#login"
    Then I find the content "Or, if you want to see what is available without signing in, click" in "div#login"
    When I click "here"
    Then I will sign in
    Then I see "csvimport, eloan, grouper, imagebrowser, imaginator, publicsearch, search, searchmedia, taxoneditor, toolbox, uploadmedia, workflo" in "div#content-main"
    #Then I see "Sign Out" in "a.expandInfo"
    When I click "Sign out"
    Then I find the content "eloan, imagebrowser, imaginator, publicsearch, search, searchmedia" in "div#content"
