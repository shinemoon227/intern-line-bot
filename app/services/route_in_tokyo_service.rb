require 'net/http'
require 'uri'
require 'json'
require 'pp'

class RouteInTokyoService

	def initialize(line_text)
		@text = line_text.split("\n")
	end

	def route_in_tokyo(src, dst)
		path = URI.escape("https://api.trip2.jp/ex/tokyo/v1.0/json?src=#{src}&dst=#{dst}&key=キー")
		return self.route_string(path)
	end

	def route_length()
		return @text.length
	end

	class << self

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
			result = ""
			route["ways"].each{|value|
				departure = departure_station_name(value)
				arrival = arrival_station_name(value)
				line = line_name(value)
				result += "#{departure} -> #{arrival} (#{line}) "
			}
			return result
		end

		# https://qiita.com/awakia/items/bd8c1385115df27c15fa
		def route_string(location, limit = 10)
			raise ArgumentError, 'too many HTTP redirects' if limit == 0
			uri = URI.parse(location)
			begin
				response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
					http.open_timeout = 5
					http.read_timeout = 10
					http.get(uri.request_uri)
				end
				case response
				when Net::HTTPSuccess
					json = response.body
					result = JSON.parse(json)
					return route_detail(result)
				when Net::HTTPRedirection
					location = response['location']
					warn "redirected to #{location}"
					route_string(location, limit - 1)
				else
					return [uri.to_s, response.value].join(" : ")
				end
			rescue => e
				return [uri.to_s, e.class, e].join(" : ")
			end
		end

	end

	private_class_method :departure_station_name, :arrival_station_name, :line_name, :route_detail, :route_string

end