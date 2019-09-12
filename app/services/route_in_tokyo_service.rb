require 'net/http'
require 'uri'
require 'json'
require 'pp'

class RouteInTokyoService

	def get_src_station(each_route)
		return each_route["src_station"]["station_name"]
	end

	def get_dst_station(each_route)
		return each_route["dst_station"]["station_name"]
	end
	
	def get_line(each_route)
		return each_route["line"]["line_name"]
	end

	def get_route_in_tokyo(src, dst)
		path = URI.escape("https://api.trip2.jp/ex/tokyo/v1.0/json?src=#{src}&dst=#{dst}&key=キー")
		uri = URI.parse(path)
		json = Net::HTTP.get(uri)
		#result = JSON.pretty_generate(JSON.parse(json))
		result = JSON.parse(json)
		return result
	end

	def get_route_detail(route)
		result = ""
		route["ways"].each{|value|
			src = get_src_station(value)
			dst = get_dst_station(value)
			line = get_line(value)
			result += "#{src} -> #{dst} (#{line}) "
		}
		return result
	end

end