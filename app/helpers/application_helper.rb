module ApplicationHelper
  include MetaTags::ViewHelper
  def default_meta_tags
    {
      site: "MotiPet",
      title: "ペット育成型タスク管理アプリ",
      reverse: false,
      charset: "utf-8",
      description: "日々のタスクの達成がペットの成長に直結します。",
      keywords: "MotiPet, ペット育成, タスク管理, モチベーション",
      canonical: request.original_url,
      separator: "|",
      icon: [
        { href: image_url("logo.svg") },
        { href: image_url("apple-touch-icon.png"), rel: "apple-touch-icon", sizes: "180x180", type: "image/png" }
      ],
      og: {
        title: :title,
        site_name: :site,
        description: :description,
        type: "website",
        url: request.original_url,
        image: image_url("motipet_toppage.png"),
        local: "ja-JP"
      },
      twitter: {
        card: "summary_large_image",
        image: image_url("motipet_toppage.png")
      }
    }
  end
end
