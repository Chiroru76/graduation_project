puts "== Seeding Titles =="

titles = [
  # -----------------------------
  # タスク完了回数系
  # -----------------------------
  {
    key: "todo_5",
    name: "TODO管理の第一歩",
    description: "TODOを5回完了した",
    rule_type: "todo_completion",
    threshold: 5
  },
  {
    key: "todo_10",
    name: "サクサク実行",
    description: "TODOを10回完了した",
    rule_type: "todo_completion",
    threshold: 10
  },
  {
    key: "todo_20",
    name: "TODO実行の名人",
    description: "TODOを20回完了した",
    rule_type: "todo_completion",
    threshold: 20
  },
  {
    key: "todo_50",
    name: "TODO実行の達人",
    description: "TODOを50回完了した",
    rule_type: "todo_completion",
    threshold: 50
  },
  {
    key: "todo_100",
    name: "TODO実行マスター",
    description: "TODOを100回完了した",
    rule_type: "todo_completion",
    threshold: 100
  },

  # -----------------------------
  # 習慣 タスク達成回数
  # -----------------------------
  {
    key: "habit_5",
    name: "習慣化の第一歩",
    description: "習慣を5回達成した",
    rule_type: "habit_completion",
    threshold: 5
  },
  {
    key: "habit_10",
    name: "小さな継続",
    description: "習慣を10回達成した",
    rule_type: "habit_completion",
    threshold: 10
  },
  {
    key: "habit_20",
    name: "習慣化の名人",
    description: "習慣を20回達成した",
    rule_type: "habit_completion",
    threshold: 20
  },
  {
    key: "habit_50",
    name: "習慣化の達人",
    description: "習慣を50回達成した",
    rule_type: "habit_completion",
    threshold: 50
  },
  {
    key: "habit_100",
    name: "習慣化マスター",
    description: "習慣を100回達成した",
    rule_type: "habit_completion",
    threshold: 100
  },

  # -----------------------------
  # ペットレベル系
  # -----------------------------
  {
    key: "pet_lv5",
    name: "育成初心者",
    description: "ペットのレベルが5に到達した",
    rule_type: "pet_level",
    threshold: 5
  },
  {
    key: "pet_lv10",
    name: "育成の名人",
    description: "ペットのレベルが10に到達した",
    rule_type: "pet_level",
    threshold: 10
  },
  {
    key: "pet_lv20",
    name: "育成の達人",
    description: "ペットのレベルが20に到達した",
    rule_type: "pet_level",
    threshold: 20
  }
]

titles.each do |attrs|
  Title.find_or_create_by!(key: attrs[:key]) do |title|
    title.name        = attrs[:name]
    title.description = attrs[:description]
    title.rule_type   = attrs[:rule_type]
    title.threshold   = attrs[:threshold]
    title.active      = true
  end
end

puts "== Titles seeded: #{Title.count} =="
