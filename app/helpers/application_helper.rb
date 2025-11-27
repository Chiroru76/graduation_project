module ApplicationHelper
  include MetaTags::ViewHelper
  def show_meta_tags
    assign_meta_tags if display_meta_tags.blank?
    display_meta_tags
  end

  def assign_meta_tags(options = {})
    defaults = t("meta_tags.defaults")
    options.reverse_merge!(defaults)
    site = options[:site]
    title = options[:title]
    canonical = options[:canonical].presence || options[:url].presence || request.original_url
    image = options[:image].presence || image_url("motipet_toppage.png")
    configs = {
      separator: "|",
      reverse: false,
      site:,
      title:,
      description: "日々のタスクの達成がペットの成長に直結します。",
      keywords: "MotiPet, ペット育成, タスク管理, モチベーション",
      canonical: request.original_url,
      icon: [
        { href: image_url("logo.svg") },
        { href: image_url("apple-touch-icon.png"), rel: "apple-touch-icon", sizes: "180x180", type: "image/png" }
      ],
      og: {
        type: "website",
        title: title.presence || site,
        description: :description,
        url: request.original_url,
        image:,
        site_name: site
      },
      twitter: {
        site:,
        card: "summary_large_image",
        image:
      }
    }
    set_meta_tags(configs)
  end
end
