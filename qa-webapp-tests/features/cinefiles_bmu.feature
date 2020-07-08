Feature: The BAMPFA uploadmedia application
Background:

Scenario: Test image uploading functionalities in uploadmedia with both Upload... NOW and Upload... LATER
    Given I am on the "cinefiles" homepage
    Then I will sign in
    Then I click app "uploadmedia"
    When I click the button with value "View the Job Queue"
    Then I find the content "Job Number, Job Summary, Job Errors, Job Flag, Download Job Files" in "div#content-main"
    When I click the button with value "List Images That Failed to Load"
    Then I find the content "Job Number, Image Filename" in "div#content-main"
