require 'net/http'
require 'uri'
require 'json'
require 'pp'

class InvalidStationError < StandardError
end

class RouteInTokyoService

	def initialize(line_text)
		@station_list = split_station_name(line_text)
		@route_text = ""
	end

	def route_in_tokyo(src, dst)
		path = URI.escape("https://api.trip2.jp/ex/tokyo/v1.0/json?src=#{src}&dst=#{dst}&key=キー")
		uri = URI.parse(path)
		begin
			response = Net::HTTP.get_response(uri)
			hash = JSON.parse(response.body)
			route_detail(hash)
			raise InvalidStationError if !access?(response.code)
		rescue => exception
			route_error()
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

	def split_station_name(text)
		text = text.gsub(/(( |　)*(から|,|、)( |　)*)|( +|　+)/, "\n") # 「から」という文字やカンマ（前後にスペースがあっても良い）およびスペースを改行文字に置換
		text = text.gsub(/((まで|への)|([へに][至行向着移往通参])).*/, "") # 「まで」「への」および「へ行く」「に向かう」などに続く文字を消去
		text = text.gsub(/(\n)+/, "\n") # 連続した改行文字を1つにする
		splitted_list = text.split("\n")
		splitted_list.map!{ |station| (station[-1] == '駅') ? station.chop() : station }
		return splitted_list
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