module TradingView
  class PullHistory < BrowserService
    DELIMETER = /~m~\d+~m~/i
    RANGES_TO_FETCH = ['All', '5Y', '1Y', '1M']

    def initialize(browser:, market:, ticker:)
      super(browser: browser)
      @market = market
      @ticker = ticker

      @time_precision = 'h'
      @influxdb = InfluxDB::Client.new url: ENV.fetch("INFLUXDB_URL")
    end

    def call
      browser.get(url)
      sleep 15
      
      scroll_into_view('chart-toolbar')

      RANGES_TO_FETCH.each do |range|
        range_buttons[range].click
        sleep 5
      end

      received_data.each do |data|
        next unless series = is_timeseries?(data)

        write_last_fetched_data_points(series)
      end
    end

    private 

    attr_reader :market, :ticker, :influxdb, :time_precision

    def range_buttons
      find_elements(css: 'div[data-name="date-ranges-tabs"] .apply-common-tooltip').each_with_object({}) do |button, r|
        r[button.text.strip] = button
      end
    end

    def write_last_fetched_data_points(time_series)
      binding.pry
      data = time_series.map do |row|
        {
          series: series,
          values: { value: row[:value], volume: row[:volume], highest: row[:highest], lowest: row[:lowest], opening: row[:opening] },
          tags: { currency: currency },
          timestamp: InfluxDB.convert_timestamp(row[:timestamp], time_precision)
        }
      end

      influxdb.write_points(data, time_precision)
    end

    def series
      "#{market}:#{ticker}"
    end

    def currency
      @currency ||= find_text(css: '.tv-symbol-price-quote__currency')
    end

    def url
      "https://www.tradingview.com/symbols/#{market}-#{ticker}"
    end

    def received_data
      received_websocket_events.reverse.flat_map { |event| split_data(event.dig('params', 'response', 'payloadData')) }.compact
    end

    def split_data(payload_data)
      payload_data.split(DELIMETER).reject { |e| e.size < 10 }.map { |data| JSON.parse(data) }
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
      return unless data

      data.dig('p', 1, 'sds_1', 's')&.map do |d|
        v = d['v']
        {
          timestamp: Time.at(v[0]),
          opening: v[1],
          highest: v[2],
          lowest: v[3],
          value: v[4],
          volume: v[5]
        }
      end
    end
  end
end