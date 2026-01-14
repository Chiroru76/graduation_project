# frozen_string_literal: true

module Tasks
  # タスク完了処理の全体フローを管理するService Object
  # - タスク完了/再オープン処理
  # - ペットの進化/孵化検出
  # - ペットコメント生成
  # - 称号付与
  class Completer
    attr_reader :task, :user, :character

    def initialize(task, user)
      @task = task
      @user = user
      @character = user.active_character
    end

    # タスク完了処理を実行し、結果を返す
    # @return [Tasks::CompletionResult] 完了処理の結果オブジェクト
    def call
      Rails.logger.debug "[Tasks::Completer] Starting completion for task=#{task.id}, user=#{user.id}"

      # 数量ログ型の習慣は専用のlog_amountを使用
      return error_result("この習慣は数量ログで記録してください") if should_use_log_amount?

      # 進化/孵化検出の準備（完了前の状態を記録）
      growth_detector = Characters::GrowthDetector.new(character)

      # タスク完了/再オープン処理
      completed, notice = perform_completion
      Rails.logger.debug "[Tasks::Completer] Task completed=#{completed}, notice=#{notice}"

      # 進化/孵化の検出（完了後の状態と比較）
      growth_result = growth_detector.detect
      Rails.logger.debug "[Tasks::Completer] Growth result: #{growth_result}"

      # ペットのコメント生成
      pet_response = build_pet_response(growth_result, completed)

      # 称号付与処理
      unlocked_titles = unlock_titles(completed)

      # タスクを最新状態にリロード
      task.reload

      # 結果オブジェクトを構築
      CompletionResult.new(
        task: task,
        notice: notice,
        growth_result: growth_result,
        pet_response: pet_response,
        unlocked_titles: unlocked_titles
      )
    end

    private

    # 数量ログ型の習慣か？
    def should_use_log_amount?
      task.habit? && task.log?
    end

    # タスクの完了/再オープン処理を実行
    # @return [Array<Boolean, String>] [完了フラグ, 通知メッセージ]
    def perform_completion
      if task.habit? && task.open?
        task.complete!(by_user: user)
        [true, "習慣を完了しました"]
      elsif task.habit? && task.done?
        task.reopen!(by_user: user)
        [false, "習慣を未完了に戻しました"]
      elsif task.todo?
        task.complete!(by_user: user)
        [true, "TODOを完了しました"]
      else
        [false, nil]
      end
    end

    # ペットのコメントを生成
    # @param growth_result [Hash] 進化/孵化/レベルアップ情報
    # @param completed [Boolean] タスクが完了したか
    # @return [Hash] { comment: String|nil, appearance: CharacterAppearance|nil }
    def build_pet_response(growth_result, completed)
      return { comment: nil, appearance: nil } unless completed

      Rails.logger.debug "[Tasks::Completer] Building pet response..."

      event_context = {
        task_completed: true,
        task_title: task.title,
        difficulty: task.difficulty
      }

      Characters::PetResponseBuilder.new(
        character: character,
        evolution_result: growth_result,
        event_context: event_context
      ).build
    rescue StandardError => e
      Rails.logger.error "[Tasks::Completer] Failed to build pet response: #{e.message}"
      { comment: nil, appearance: nil }
    end

    # 称号付与処理
    # @param completed [Boolean] タスクが完了したか
    # @return [Array<Title>] 新規解除された称号リスト
    def unlock_titles(completed)
      return [] unless completed

      Titles::Unlocker.new(user: user).call
    end

    # エラー時の結果オブジェクトを返す
    # @param message [String] エラーメッセージ
    # @return [Tasks::CompletionResult] エラー状態の結果オブジェクト
    def error_result(message)
      CompletionResult.new(
        task: task,
        notice: message,
        growth_result: { hatched: false, evolved: false, leveled_up: false },
        pet_response: { comment: nil, appearance: nil },
        unlocked_titles: []
      )
    end
  end
end
