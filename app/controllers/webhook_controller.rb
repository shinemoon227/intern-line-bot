require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          route_service = RouteInTokyoService.new(event.message['text'])
          station_list = route_service.entered_station()
          output = ""
          len = route_service.route_length()
          if len == 2
            output = route_service.route_in_tokyo(station_list[0], station_list[1])
          elsif len < 2
            output = "駅の数が少なすぎます。駅名は2つ、改行で区切って入力してください。"
          else
            output = "駅の数が多すぎます。駅名は2つ、改行で区切って入力してください。"
          end
          message = {
            type: 'text',
            text: output
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        when Line::Bot::Event::MessageType::Location
          title = event.message['title']
          address = event.message['address'].gsub(/日本、|〒\d{3}-\d{4}/, '')
          now_location = title || address + '付近'
          message = {
            type: 'text',
            text: "あなたは現在#{now_location}にいますね？"
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }
    head :ok
  end
end
