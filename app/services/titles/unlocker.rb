module Titles
  class Unlocker
    def initialize(user:)
      @user = user
      @newly_unlocked = []
    end

    def call
      applicable_titles.find_each do |title|
        next if already_unlocked?(title)

        rule = RuleResolver.resolve(title, user: user)
        Rails.logger.debug "rule=#{rule.class}, satisfied?=#{rule.satisfied?}"
        next unless rule.satisfied?

        unlock!(title)
      end

      Rails.logger.debug "newly_unlocked=#{@newly_unlocked.map(&:id)}"

      @newly_unlocked
    end

    private

    attr_reader :user

    def applicable_titles
      Title.where(active: true)
    end

    def already_unlocked?(title)
      user.titles.exists?(id: title.id)
    end

    def unlock!(title)
      UserTitle.create!(
        user: user,
        title: title,
        unlocked_at: Time.current
      )
      @newly_unlocked << title
    end
  end
end
