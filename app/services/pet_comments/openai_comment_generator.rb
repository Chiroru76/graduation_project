module PetComments
  class OpenaiCommentGenerator
    def initialize(event:, character:, user:, context:)
      @event = event
      @character = character
      @user = user
      @context = context
    end

    def call
      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: messages,
          max_tokens: 50,
          temperature: 0.5
        }
      )

      response.dig("choices", 0, "message", "content")&.strip
    rescue StandardError => e
      Rails.logger.error "OpenAI API error: #{e.message}"
      nil
    end

    private

    attr_reader :event, :character, :user, :context

    def client
      @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    end

    def messages
      [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: user_prompt
        }
      ]
    end

    def system_prompt
      <<~PROMPT
        あなたは「#{character.character_kind.name}」という名前のペットキャラクターです。
        現在のステージ: #{character.character_kind.stage}（egg/child/adult）
        レベル: #{character.level}

        性格: 明るく、ユーザーを励ますのが好き。短くて可愛いコメントをする。

        【重要なルール】
        - 15文字以内の短いコメント（句読点含む）
        - ひらがなと漢字のみを使用
        - 「〜だね」「〜だよ」「〜だよね」など親しみやすい口調
        - ユーザーを褒めたり励ましたりする温かい内容

        【良い例】
        - "やったね、頑張ったね"
        - "すごいよ、えらいよ"
        - "その調子だよ"
        - "いい感じだね"

        【悪い例】
        - "すごいね、お掃除✨" （絵文字NG）
        - "完了" （短すぎて励ましがない）
        - "お疲れ様です" （堅苦しい）
      PROMPT
    end

    def user_prompt
      case event
      when :task_completed
        task_title = context[:task_title]
        difficulty = context[:difficulty]
        <<~PROMPT
          ユーザーが「#{task_title}」というタスク（難易度: #{difficulty}）を完了しました。
          ペットとして、短く励ましのコメントをしてください。
        PROMPT
      when :login
        "ユーザーがログインしました。歓迎のコメントをしてください。"
      when :level_up
        "レベルアップしました！喜びのコメントをしてください。"
      else
        "#{event} イベントが発生しました。コメントしてください。"
      end
    end
  end
end
