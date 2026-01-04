require "rails_helper"

RSpec.describe "Webhooks::Line", type: :request do
  let(:channel_secret) { "test_channel_secret" }
  let(:valid_body) { '{"events":[]}' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("LINE_MESSAGING_CHANNELSECRET").and_return(channel_secret)
  end

  def generate_signature(body, secret)
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, body)
    Base64.strict_encode64(hash)
  end

  # ===== POST /webhooks/line (create) =====
  describe "POST /webhooks/line" do
    context "署名検証" do
      it "正しい署名で200 OKを返す" do
        signature = generate_signature(valid_body, channel_secret)

        post webhooks_line_path, params: valid_body, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
      end

      it "署名が無効な場合は400 Bad Requestを返す" do
        invalid_signature = "invalid_signature"

        post webhooks_line_path, params: valid_body, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => invalid_signature
        }

        expect(response).to have_http_status(:bad_request)
      end

      it "署名ヘッダーがない場合は400 Bad Requestを返す" do
        post webhooks_line_path, params: valid_body, headers: {
          "Content-Type" => "application/json"
        }

        expect(response).to have_http_status(:bad_request)
      end

      it "チャンネルシークレットが環境変数にない場合は400 Bad Requestを返す" do
        allow(ENV).to receive(:[]).with("LINE_MESSAGING_CHANNELSECRET").and_return(nil)

        signature = generate_signature(valid_body, channel_secret)

        post webhooks_line_path, params: valid_body, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "followイベント処理" do
      it "既存ユーザーとline_user_idを紐付ける" do
        user = create(:user, provider: "line", uid: "U1234567890")
        follow_event = {
          events: [
            {
              type: "follow",
              source: { userId: "U1234567890" }
            }
          ]
        }.to_json

        signature = generate_signature(follow_event, channel_secret)

        post webhooks_line_path, params: follow_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.line_user_id).to eq("U1234567890")
      end

      it "line_user_idで既存ユーザーを見つけて更新する" do
        user = create(:user, line_user_id: "U1234567890")
        follow_event = {
          events: [
            {
              type: "follow",
              source: { userId: "U1234567890" }
            }
          ]
        }.to_json

        signature = generate_signature(follow_event, channel_secret)

        post webhooks_line_path, params: follow_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.line_user_id).to eq("U1234567890")
      end

      it "ユーザーが見つからない場合もエラーにならない" do
        follow_event = {
          events: [
            {
              type: "follow",
              source: { userId: "unknown_user" }
            }
          ]
        }.to_json

        signature = generate_signature(follow_event, channel_secret)

        post webhooks_line_path, params: follow_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "unfollowイベント処理" do
      it "ユーザーのline_user_idをnilにする" do
        user = create(:user, line_user_id: "U1234567890")
        unfollow_event = {
          events: [
            {
              type: "unfollow",
              source: { userId: "U1234567890" }
            }
          ]
        }.to_json

        signature = generate_signature(unfollow_event, channel_secret)

        post webhooks_line_path, params: unfollow_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.line_user_id).to be_nil
      end

      it "ユーザーが見つからない場合もエラーにならない" do
        unfollow_event = {
          events: [
            {
              type: "unfollow",
              source: { userId: "unknown_user" }
            }
          ]
        }.to_json

        signature = generate_signature(unfollow_event, channel_secret)

        post webhooks_line_path, params: unfollow_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "その他のイベント" do
      it "未知のイベントタイプでも200 OKを返す" do
        unknown_event = {
          events: [
            {
              type: "message",
              message: { type: "text", text: "Hello" }
            }
          ]
        }.to_json

        signature = generate_signature(unknown_event, channel_secret)

        post webhooks_line_path, params: unknown_event, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "JSONパースエラー" do
      it "不正なJSONで400 Bad Requestを返す" do
        invalid_json = "{ invalid json }"
        signature = generate_signature(invalid_json, channel_secret)

        post webhooks_line_path, params: invalid_json, headers: {
          "Content-Type" => "application/json",
          "X-Line-Signature" => signature
        }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
