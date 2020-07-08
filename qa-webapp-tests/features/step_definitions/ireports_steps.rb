Then(/^I select a report called "([^"]*)"$/) do |report|
    find(:link_or_button, report).click
end

Then(/^I will see the correct report in pdf format$/) do 
    # Screenshot appears; please verify the results of the Search for Images.
    #  screenshot_and_open_image
    page.evaluate_script('window.history.back()')
end

Then(/^I click the link with text "([^"]*)"$/) do |link_text|
    find(:xpath, "//a[text()='#{link_text}']").click
end