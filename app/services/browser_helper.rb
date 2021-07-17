# Small helpers that help interacting with real webpage
module BrowserHelper
  WEBSOCKET_EVENTS = ['Network.webSocketFrameReceived']  #, 'Network.webSocketFrameSent'] #, 'Network.responseReceived', 'Network.requestWillBeSent']

  IGNORE_ERRORS = [
    Selenium::WebDriver::Error::NoSuchElementError,
    Selenium::WebDriver::Error::ElementNotInteractableError,
    Selenium::WebDriver::Error::ElementClickInterceptedError,
  ].freeze

  def wait(timeout)
    Selenium::WebDriver::Wait.new(timeout: timeout, ignore: IGNORE_ERRORS)
  end

  def scroll_top
    browser.execute_script 'window.scrollTo(0, 0)'
    sleep 1
  end

  def scroll_bottom
    browser.execute_script 'window.scrollTo(0, document.body.scrollHeight)'
  end

  def find_element(timeout: 10, **args)
    wait(timeout).until { browser.find_element(args) }
  end

  def find_elements(timeout: 10, **args)
    wait(timeout).until { browser.find_elements(args) }
  end

  def find_text(timeout: 60, **args)
    wait(timeout).until do
      text = browser.find_element(args)&.text&.strip
      return text if text.present?
    end
  end

  def build_kv(item_css, key_css, val_css)
    find_elements(css: item_css).each_with_object({}) do |row, result|
      begin
        key_col = row.find_element(css: key_css)
        val_row = row.find_element(css: val_css)
        result[key_col.text.strip] = val_row.text.strip
      rescue Selenium::WebDriver::Error::NoSuchElementError
      end
    end
  end

  def received_websocket_events
    events = browser.logs.get('performance')

    events.map { |event| JSON.parse(event.message)['message'] }.filter { |log| WEBSOCKET_EVENTS.include?(log['method']) }
  end
end