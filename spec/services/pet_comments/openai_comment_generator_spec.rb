require "rails_helper"

RSpec.describe PetComments::OpenaiCommentGenerator, type: :service do
  before(:all) do
    setup_master_data
  end

  describe "#call" do
    let(:user) { create(:user) }
    let(:character) { user.active_character }
    let(:event) { :task_completed }
    let(:context) { { task_title: "部屋の掃除", difficulty: "medium" } }
    let(:generator) do
      described_class.new(
        event: event,
        character: character,
        user: user,
        context: context
      )
    end

    let(:openai_client) { instance_double(OpenAI::Client) }
    let(:openai_response) do
      {
        "choices" => [
          {
            "message" => {
              "content" => "やったね、頑張ったね"
            }
          }
        ]
      }
    end

    before do
      allow(OpenAI::Client).to receive(:new).and_return(openai_client)
    end

    context "正常にコメントが生成される場合" do
      before do
        allow(openai_client).to receive(:chat).and_return(openai_response)
      end

      it "OpenAI APIからコメントを取得できること" do
        result = generator.call
        expect(result).to eq("やったね、頑張ったね")
      end

      it "OpenAI::Clientが正しいパラメータで呼ばれること" do
        expect(openai_client).to receive(:chat).with(
          parameters: {
            model: "gpt-4o",
            messages: array_including(
              hash_including(role: "system"),
              hash_including(role: "user")
            ),
            max_tokens: 50,
            temperature: 0.5
          }
        )
        generator.call
      end

      it "systemプロンプトにキャラクター情報が含まれること" do
        generator.call
        expect(openai_client).to have_received(:chat) do |args|
          system_message = args[:parameters][:messages].find { |m| m[:role] == "system" }
          expect(system_message[:content]).to include(character.character_kind.name)
          expect(system_message[:content]).to include(character.character_kind.stage)
          expect(system_message[:content]).to include(character.level.to_s)
        end
      end
    end

    context "タスク完了イベントの場合" do
      let(:event) { :task_completed }
      let(:context) { { task_title: "読書", difficulty: "easy" } }

      before do
        allow(openai_client).to receive(:chat).and_return(openai_response)
      end

      it "userプロンプトにタスク情報が含まれること" do
        generator.call
        expect(openai_client).to have_received(:chat) do |args|
          user_message = args[:parameters][:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include("読書")
          expect(user_message[:content]).to include("easy")
        end
      end
    end

    context "ログインイベントの場合" do
      let(:event) { :login }
      let(:context) { {} }

      before do
        allow(openai_client).to receive(:chat).and_return(openai_response)
      end

      it "適切なプロンプトが生成されること" do
        generator.call
        expect(openai_client).to have_received(:chat) do |args|
          user_message = args[:parameters][:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include("ログイン")
        end
      end
    end

    context "レベルアップイベントの場合" do
      let(:event) { :level_up }
      let(:context) { {} }

      before do
        allow(openai_client).to receive(:chat).and_return(openai_response)
      end

      it "適切なプロンプトが生成されること" do
        generator.call
        expect(openai_client).to have_received(:chat) do |args|
          user_message = args[:parameters][:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include("レベルアップ")
        end
      end
    end

    context "OpenAI APIがエラーを返す場合" do
      before do
        allow(openai_client).to receive(:chat).and_raise(StandardError.new("API Error"))
      end

      it "nilを返すこと" do
        result = generator.call
        expect(result).to be_nil
      end

      it "エラーログが記録されること" do
        expect(Rails.logger).to receive(:error).with(/OpenAI API error/)
        generator.call
      end
    end

    context "OpenAI APIが空のレスポンスを返す場合" do
      let(:empty_response) { { "choices" => [] } }

      before do
        allow(openai_client).to receive(:chat).and_return(empty_response)
      end

      it "nilを返すこと" do
        result = generator.call
        expect(result).to be_nil
      end
    end

    context "OpenAI APIが空白のコメントを返す場合" do
      let(:blank_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "   "
              }
            }
          ]
        }
      end

      before do
        allow(openai_client).to receive(:chat).and_return(blank_response)
      end

      it "空文字列を返すこと" do
        result = generator.call
        expect(result).to eq("")
      end
    end
  end
end
