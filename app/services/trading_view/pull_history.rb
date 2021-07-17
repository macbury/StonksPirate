module TradingView
  class PullHistory < BrowserService
    DELIMETER = /~m~\d+~m~/i

    def initialize(browser:, market:, ticker:)
      super(browser: browser)
      @market = market
      @ticker = ticker
    end

    def call
      browser.get(url)
      
      sleep 15
      scroll_bottom
      
      timeseries(received_data.find { |data| is_timeseries?(data) })
    end

    private 

    attr_reader :market, :ticker

    def url
      "https://www.tradingview.com/symbols/#{market}-#{ticker}"
    end

    def click_on_all_date_range
      find_elements(css: 'div[data-name="date-ranges-tabs"] .apply-common-tooltip').last.click
    end

    def received_data
      received_websocket_events.flat_map { |event| split_data(event.dig('params', 'response', 'payloadData')) }.compact
    end

    def split_data(payload_data)
      payload_data.split(DELIMETER).reject { |e| e.size < 10 }.map { |data| JSON.parse(data) }
    rescue JSON::ParserError => e
      binding.pry
    end

    def is_timeseries?(data)
      return unless data['m'] == 'timescale_update'
      
      timeseries(data)
    end

    # {
    #     "i": 48,
    #     "v": [
    #         1491202800, # date 2017-04-03 09:00:00 +0200
    #         4.63, # opening
    #         5.34, # highest price
    #         4.46, # lowest price
    #         5.17,# closing price?
    #         127042 # volumen
    #     ]
    # },
    #
    def timeseries(data)
      data.dig('p', 1, 'sds_1', 's').map do |d|
        v = d['v']
        {
          timestamp: v[0],
          opening: v[1],
          highest: v[2],
          lowest: v[3],
          price: v[4],
          volume: v[5]
        }
      end
    end
  end
end