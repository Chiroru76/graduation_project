class Webhooks::LineController < ActionController::API
    # POST /webhooks/line
    # エンドポイントに届いたLINEウェブフックを受け取り処理する
    # - 署名検証(valid_signature?)
    # - イベントごとに振り分け (follow / unfollow)
    # - JSONパースエラーは400で応答
    def create
        body = request.raw_post

        return head :bad_request unless valid_signature?(body)

        events = JSON.parse(body)['events'] || []
        events.each do |event|
            case event['type']
            when 'follow'
                handle_follow(event)
            when 'unfollow'
                handle_unfollow(event)
            else
                Rails.logger.info("LINE event ignored: #{event['type']}")
            end
        end

        head :ok
    rescue JSON::ParserError => e
        Rails.logger.warn("LINE webhook JSON parse error: #{e.class} request_id=#{request.request_id}")
        head :bad_request
    end

    private

    # valid_signature?(body)
    # - 環境変数からチャンネルシークレットを読み取り、リクエストヘッダの署名と照合する
    # - 不足や検証失敗時はfalseを返す
    def valid_signature?(body)
        secret = ENV['LINE_MESSAGING_CHANNELSECRET']
        unless secret.present?
            Rails.logger.error("[LINE] missing channel secret env var (LINE_MESSAGING_CHANNELSECRET etc.)")
            return false
        end

        signature = request.headers['X-Line-Signature']
        return false if signature.blank?

        begin
            hash = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, body)
            Base64.strict_encode64(hash) == signature
        rescue => e
            Rails.logger.error("[LINE] signature verification error: #{e.class} #{e.message}")
            false
        end
    end

    # handle_follow(event)
    # - followイベントを処理する
    # - イベントからLINEのuserIdを取得し、既存Userと紐付けを試みる
    # - 見つかればline_user_idを更新しログを残す。見つからなければその旨をログに残す
    def handle_follow(event)
        user_id = event.dig('source', 'userId')
        return if user_id.blank?

        # 既存ユーザーとの紐付け
        user = User.find_by(provider: 'line', uid: user_id) ||
                     User.find_by(line_user_id: user_id)

        if user
            user.update(line_user_id: user_id)
            Rails.logger.info("Linked LINE user_id=#{user_id} -> user_id=#{user.id}")
        else
            # ユーザーが見つからない場合の対応例：ログ残す
            Rails.logger.info("LINE follow received for unknown user_id=#{user_id}. Consider prompting to link account.")
        end
    end

    # handle_unfollow(event)
    # - unfollowイベントを処理する
    # - イベントからLINEのuserIdを取得し、紐付け解除 (line_user_idをnilに設定) を行う
    def handle_unfollow(event)
        user_id = event.dig('source', 'userId')
        return if user_id.blank?
        user = User.find_by(line_user_id: user_id)
        return unless user
        user.update(line_user_id: nil)
        Rails.logger.info("Unlinked LINE user_id=#{user_id} from user_id=#{user.id}")
    end
end
