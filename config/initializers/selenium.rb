# https://www.selenium.dev/selenium/docs/api/rb/Selenium/WebDriver/Driver.html
# https://github.com/oesmith/puffing-billy/blob/8b5d92184b8e275150bcb4dc818bcca94f080302/lib/billy/browsers/capybara.rb#L53
BROWSER_POOL = ConnectionPool.new(size: 10, timeout: 1.minutes) do
  caps =  Selenium::WebDriver::Remote::Capabilities.chrome(
    'goog:loggingPrefs' => {
      performance: 'ALL'
    }
  )

  driver = Selenium::WebDriver.for(:remote, url: "http://localhost:4444/wd/hub", capabilities: [caps])
  driver.manage.window.maximize
  driver
end

at_exit do
  BROWSER_POOL&.shutdown do |browser|
    browser.close rescue nil
  end
  exit
end