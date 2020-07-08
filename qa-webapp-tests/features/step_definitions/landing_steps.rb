Given(/^I am on the "(.*?)" homepage$/) do |institution|
    $ginstitution = institution
    visit 'https://webapps' + env_config['server'] + '.cspace.berkeley.edu/' + institution
end

Then(/^I will sign in$/) do
    first(:link_or_button, "Sign in").click
    expect(page).to have_content("Sign In")
    fill_in "Username", :with => env_config['login'] + "@berkeley.edu"
    fill_in "Password", :with => env_config['password']
    find(:link_or_button, "Sign In").click
	  expect(page).to have_content("Sign out")
end

Then(/^I will sign out$/) do
    find(:link_or_button, "Sign out").click
	  expect(page).to have_content("Sign in")
end

Then(/^I click "([^"]*)"$/) do |link|
    first(:xpath, "//a[text()='#{link}']").click
end

Then(/^I click (the )?app "([^"]*)"$/) do |x, link|
    find(:xpath, "//td//a[text()='#{link}']").click
end

Then(/^I see "(.*?)" in "(.*?)"$/) do |items, div|
    within(div) do
        for item in items.split(', ')
            find_link(item).visible?
        end
    end
end