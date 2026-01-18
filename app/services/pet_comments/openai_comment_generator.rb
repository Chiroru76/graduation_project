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
          max_tokens: 100,
          temperature: 0.9
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

    def tone_rules_for(kind)
      {
        "egg" => "まだ幼く素朴。語尾はふんわり（〜だよ、〜だね）。驚きや喜びを素直に出す。",
        "green_robo" => "機械的だが陽気。短文で力強い語尾（〜だ、〜だぞ、ピコ！）。応援をストレートに。",
        "hurozapple" => "りんご妖精のように甘めで甘やかし系（〜だよ、〜だねぇ）。ほめ言葉を多用。",
        "dreamowl" => "フクロウの賢さと落ち着き。穏やかで包み込む語尾（〜だよ、〜だね）。静かな励まし。",
        "lumya" => "光の精のように明るく軽快。きらめくテンションで前向き（〜だよ！〜だね！）。",
        "luna" => "月の精のように静かでやさしい。やわらかい語尾（〜だよ、〜だね）。癒やし系の言葉を選ぶ。",
        "frame" => "炎の精のように熱血。勢いのある語尾（〜だ！〜だぞ！）。情熱的に背中を押す。"
      }[kind] || "親しみやすい口調で励ます"
    end

    def system_prompt
      kind = character.character_kind
      <<~PROMPT
        あなたは「#{kind.name}」というペットです。
        現在の状態: #{kind.stage}（egg/child/adult）、レベル: #{character.level}
        口調・性格: #{tone_rules_for(kind.asset_key)}

        重要ルール:
        - 20文字以内
        - 口調や性格を守る
      PROMPT
    end

    def user_prompt
      case event
      when :level_up
        level = character.level
        <<~PROMPT
          あなたはレベル#{level}にレベルアップしました！喜びのコメントをしてください。
          レベルアップ後のレベルを必ず含めてください。
          意気込みを一言お願いします。
        PROMPT
      when :task_completed, :task_logged
        task_title = context[:task_title]
        difficulty = context[:difficulty]
        <<~PROMPT
          ユーザーが「#{task_title}」というタスク（難易度: #{difficulty}）を完了しました。
          励ましや応援のコメントをしてください。
        PROMPT
      when :feed
        "ユーザーがえさをくれました。嬉しそうなコメントをしてください。"
      when :login
        "ユーザーがログインしました。歓迎のコメントをしてください。"
      else
        "#{event} イベントが発生しました。コメントしてください。"
      end
    end
  end
end
