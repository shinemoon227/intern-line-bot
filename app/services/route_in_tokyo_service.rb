require 'net/http'
require 'uri'
require 'json'
require 'pp'

class InvalidStationError < StandardError
end

class RouteInTokyoService

	def initialize(line_text)
		@station_list = line_text.split("\n")
		@route_text = ""
	end

	def route_in_tokyo(src, dst)
		path = URI.escape("https://api.trip2.jp/ex/tokyo/v1.0/json?src=#{src}&dst=#{dst}&key=キー")
		uri = URI.parse(path)
		begin
			response = Net::HTTP.get_response(uri)
			raise InvalidStationError if !access?(response.code)
		rescue => exception
			route_error()
		else
			hash = JSON.parse(response.body)
			route_detail(hash)
		end
		return @route_text
	end

	def entered_station()
		return @station_list
	end

	def route_length()
		return @station_list.length
	end

	private

	def access?(code)
		return code == "200"
	end

	def departure_station_name(each_route)
		return each_route["src_station"]["station_name"]
	end

	def arrival_station_name(each_route)
		return each_route["dst_station"]["station_name"]
	end
	
	def line_name(each_route)
		return each_route["line"]["line_name"]
	end

	def route_detail(route)
		route["ways"].each{|value|
			departure = departure_station_name(value)
			arrival = arrival_station_name(value)
			line = line_name(value)
			@route_text += "#{departure} -> #{arrival} (#{line}) "
		}
	end

	def route_error()
		@route_text = "経路が存在しませんでした。駅名は正確に入力できていますか？\nまた、対応している駅は東京都およびその周辺の一部に限ります。"
	end

end