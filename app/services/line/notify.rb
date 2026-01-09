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

        if response.is_a?(Line::Bot::V2::MessagingApi::ErrorResponse)
          message = response.message
          Rails.logger.error("[LINE] push_message failed: #{message}")
          raise StandardError, message
        end

        Rails.logger.info("[LINE] push_message success")
        response
      rescue StandardError => e
        Rails.logger.error("[LINE] send_message failed: #{e.class}: #{e.message}")
        raise
      end
    end
  end
end
