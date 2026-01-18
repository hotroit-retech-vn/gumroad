# frozen_string_literal: true

return if ENV["SKIP_TAXONOMY_CREATION"] == "1"
return if Taxonomy.where(slug: "vibe-coding-ai-apps").exists?

# 1. Vibe Coding & AI Apps
vibe_coding = Taxonomy.find_or_create_by!(slug: "vibe-coding-ai-apps")
Taxonomy.find_or_create_by!(slug: "ung-dung", parent: vibe_coding)
Taxonomy.find_or_create_by!(slug: "web-ai-tools", parent: vibe_coding)
Taxonomy.find_or_create_by!(slug: "mobile-ai-tools", parent: vibe_coding)

# 2. AI Automation
ai_automation = Taxonomy.find_or_create_by!(slug: "ai-automation")
Taxonomy.find_or_create_by!(slug: "n8n-workflows", parent: ai_automation)
Taxonomy.find_or_create_by!(slug: "ai-agents", parent: ai_automation)
Taxonomy.find_or_create_by!(slug: "tu-dong-hoa-marketing", parent: ai_automation)
Taxonomy.find_or_create_by!(slug: "tu-dong-hoa-ban-hang", parent: ai_automation)

# 3. Prompt & Creative Assets
prompt_creative = Taxonomy.find_or_create_by!(slug: "prompt-creative-assets")
Taxonomy.find_or_create_by!(slug: "thu-vien-prompt-chatgpt", parent: prompt_creative)
Taxonomy.find_or_create_by!(slug: "thu-vien-prompt-claude", parent: prompt_creative)
Taxonomy.find_or_create_by!(slug: "video-templates", parent: prompt_creative)
Taxonomy.find_or_create_by!(slug: "digital-human-templates", parent: prompt_creative)

# 4. Accounts & Premium Access
accounts_premium = Taxonomy.find_or_create_by!(slug: "accounts-premium-access")
Taxonomy.find_or_create_by!(slug: "cursor-pro", parent: accounts_premium)
Taxonomy.find_or_create_by!(slug: "windsurf", parent: accounts_premium)
Taxonomy.find_or_create_by!(slug: "capcut", parent: accounts_premium)
Taxonomy.find_or_create_by!(slug: "canva", parent: accounts_premium)
Taxonomy.find_or_create_by!(slug: "api-keys", parent: accounts_premium)

# 5. Khóa học
khoa_hoc = Taxonomy.find_or_create_by!(slug: "khoa-hoc")
Taxonomy.find_or_create_by!(slug: "khoa-hoc-vibe-coding", parent: khoa_hoc)
Taxonomy.find_or_create_by!(slug: "prompt-engineering", parent: khoa_hoc)
Taxonomy.find_or_create_by!(slug: "ai-marketing", parent: khoa_hoc)

# 6. VPS, Server
vps_server = Taxonomy.find_or_create_by!(slug: "vps-server")
Taxonomy.find_or_create_by!(slug: "llm-chatbot", parent: vps_server)
Taxonomy.find_or_create_by!(slug: "gpu", parent: vps_server)

# 7. Flux2
Taxonomy.find_or_create_by!(slug: "flux2")

# 8. Ngân hàng
Taxonomy.find_or_create_by!(slug: "ngan-hang")

# 9. n8n (top-level)
Taxonomy.find_or_create_by!(slug: "n8n")

# Other (fallback category)
Taxonomy.find_or_create_by!(slug: "other")
