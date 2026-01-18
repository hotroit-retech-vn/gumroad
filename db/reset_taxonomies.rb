# frozen_string_literal: true

# Script to reset taxonomies
# Run with: rails runner db/reset_taxonomies.rb

puts "=" * 50
puts "RESETTING TAXONOMIES"
puts "=" * 50

# Step 1: Clear cache
puts "\n1. Clearing Rails cache..."
Rails.cache.delete("taxonomies_for_nav")
Rails.cache.clear
puts "   Cache cleared!"

# Step 2: Delete all old taxonomies
puts "\n2. Deleting existing taxonomies..."
old_count = Taxonomy.count
Taxonomy.delete_all  # Use delete_all to skip callbacks
TaxonomyHierarchy.delete_all if defined?(TaxonomyHierarchy)
puts "   Deleted #{old_count} old taxonomies"

# Step 3: Create new taxonomies
puts "\n3. Creating new taxonomies..."

# 1. Vibe Coding & AI Apps
vibe_coding = Taxonomy.create!(slug: "vibe-coding-ai-apps")
Taxonomy.create!(slug: "ung-dung", parent: vibe_coding)
Taxonomy.create!(slug: "web-ai-tools", parent: vibe_coding)
Taxonomy.create!(slug: "mobile-ai-tools", parent: vibe_coding)

# 2. AI Automation
ai_automation = Taxonomy.create!(slug: "ai-automation")
Taxonomy.create!(slug: "n8n-workflows", parent: ai_automation)
Taxonomy.create!(slug: "ai-agents", parent: ai_automation)
Taxonomy.create!(slug: "tu-dong-hoa-marketing", parent: ai_automation)
Taxonomy.create!(slug: "tu-dong-hoa-ban-hang", parent: ai_automation)

# 3. Prompt & Creative Assets
prompt_creative = Taxonomy.create!(slug: "prompt-creative-assets")
Taxonomy.create!(slug: "thu-vien-prompt-chatgpt", parent: prompt_creative)
Taxonomy.create!(slug: "thu-vien-prompt-claude", parent: prompt_creative)
Taxonomy.create!(slug: "video-templates", parent: prompt_creative)
Taxonomy.create!(slug: "digital-human-templates", parent: prompt_creative)

# 4. Accounts & Premium Access
accounts_premium = Taxonomy.create!(slug: "accounts-premium-access")
Taxonomy.create!(slug: "cursor-pro", parent: accounts_premium)
Taxonomy.create!(slug: "windsurf", parent: accounts_premium)
Taxonomy.create!(slug: "capcut", parent: accounts_premium)
Taxonomy.create!(slug: "canva", parent: accounts_premium)
Taxonomy.create!(slug: "api-keys", parent: accounts_premium)

# 5. Khóa học
khoa_hoc = Taxonomy.create!(slug: "khoa-hoc")
Taxonomy.create!(slug: "khoa-hoc-vibe-coding", parent: khoa_hoc)
Taxonomy.create!(slug: "prompt-engineering", parent: khoa_hoc)
Taxonomy.create!(slug: "ai-marketing", parent: khoa_hoc)

# 6. VPS, Server
vps_server = Taxonomy.create!(slug: "vps-server")
Taxonomy.create!(slug: "n8n", parent: vps_server)
Taxonomy.create!(slug: "llm-chatbot", parent: vps_server)
Taxonomy.create!(slug: "gpu", parent: vps_server)

# Other
Taxonomy.create!(slug: "other")

puts "   Created #{Taxonomy.count} new taxonomies"

# Step 4: Verify
puts "\n4. Current taxonomies in database:"
puts "-" * 40
Taxonomy.where(parent_id: nil).each do |root|
  puts "  • #{root.slug}"
  Taxonomy.where(parent_id: root.id).each do |child|
    puts "    └── #{child.slug}"
  end
end

puts "\n" + "=" * 50
puts "DONE! Please restart your Rails server."
puts "=" * 50
