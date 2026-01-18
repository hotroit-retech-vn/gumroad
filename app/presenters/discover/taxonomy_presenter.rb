# frozen_string_literal: true

class Discover::TaxonomyPresenter
  TAXONOMY_LABELS = {
    # 1. Vibe Coding & AI Apps
    "vibe-coding-ai-apps" => "Vibe Coding & AI Apps",
    "ung-dung" => "Ứng dụng",
    "web-ai-tools" => "Web AI Tools",
    "mobile-ai-tools" => "Mobile AI Tools",

    # 2. AI Automation
    "ai-automation" => "AI Automation",
    "n8n-workflows" => "n8n Workflows",
    "ai-agents" => "AI Agents",
    "tu-dong-hoa-marketing" => "Tự động hóa Marketing",
    "tu-dong-hoa-ban-hang" => "Tự động hóa Bán hàng",

    # 3. Prompt & Creative Assets
    "prompt-creative-assets" => "Prompt & Creative Assets",
    "thu-vien-prompt-chatgpt" => "Thư viện Prompt ChatGPT",
    "thu-vien-prompt-claude" => "Thư viện Prompt Claude",
    "video-templates" => "Video Templates",
    "digital-human-templates" => "Digital Human Templates",

    # 4. Accounts & Premium Access
    "accounts-premium-access" => "Accounts & Premium Access",
    "cursor-pro" => "Cursor Pro",
    "windsurf" => "Windsurf",
    "capcut" => "CapCut",
    "canva" => "Canva",
    "api-keys" => "API Keys",

    # 5. Khóa học
    "khoa-hoc" => "Khóa học",
    "khoa-hoc-vibe-coding" => "Khóa học Vibe Coding",
    "prompt-engineering" => "Prompt Engineering",
    "ai-marketing" => "AI Marketing",

    # 6. VPS, Server
    "vps-server" => "VPS, Server",
    "llm-chatbot" => "LLM Chatbot",
    "gpu" => "GPU",

    # 7. Flux2
    "flux2" => "Flux2",

    # 8. Ngân hàng
    "ngan-hang" => "Ngân hàng",

    # 9. n8n (top-level)
    "n8n" => "n8n",

    # Other
    "other" => "Other"
  }

  def taxonomies_for_nav(recommended_products: nil)
    taxonomies = Rails.cache.fetch("taxonomies_for_nav", expires_in: 1.hour) do
      Taxonomy.all.eager_load(:taxonomy_stat).sort_by do |taxonomy|
        if taxonomy.slug == "other"
          [1, taxonomy.slug]
        else
          [-taxonomy.taxonomy_stat&.recent_sales_count.to_i, taxonomy.slug]
        end
      end.map do |taxonomy|
        {
          key: taxonomy.id.to_s,
          label: TAXONOMY_LABELS[taxonomy.slug] || taxonomy.slug.titleize,
          slug: taxonomy.slug,
          parent_key: taxonomy.parent_id&.to_s
        }
      end
    end

    taxonomy_ids = recommended_products&.filter_map(&:taxonomy_id)
    if taxonomy_ids.present?
      sorted_roots = (Taxonomy.includes(:self_and_ancestors).where(self_and_ancestors: { parent_id: nil }).find(taxonomy_ids)).each_with_object({}).with_index do |(taxonomy, hash), index|
        hash[taxonomy.self_and_ancestors.first.slug] ||= taxonomy_ids.size - index
      end
      taxonomies = taxonomies.sort_by.with_index { |taxonomy, index| [-(sorted_roots[taxonomy[:slug]] || 0), index] }
    end

    taxonomies
  end
end
