require "line-bot-api"

module Line
  module Notify
    class << self
      def client
        @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
          channel_access_token: ENV.fetch("LINE_MESSAGING_TOKEN")
        )
      end

      def send_message(line_user_id, message)
        return unless line_user_id.present?

        request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
          to: line_user_id,
          messages: [
            Line::Bot::V2::MessagingApi::TextMessage.new(text: message)
          ]
        )

        response = client.push_message(push_message_request: request)

        Rails.logger.info("[LINE] push_message success")
        response
      rescue => e

        Rails.logger.error("[LINE] send_message failed: #{e.class}: #{e.message}")
        raise e
      end
    end
  end
end
