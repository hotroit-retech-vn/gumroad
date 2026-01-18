# frozen_string_literal: true

# MoMo Payment Gateway Configuration
# Documentation: https://developers.momo.vn

# MoMo API Credentials
MOMO_PARTNER_CODE = GlobalConfig.get("MOMO_PARTNER_CODE")
MOMO_ACCESS_KEY = GlobalConfig.get("MOMO_ACCESS_KEY")
MOMO_SECRET_KEY = GlobalConfig.get("MOMO_SECRET_KEY")

# MoMo API Endpoint
# Production: https://payment.momo.vn
# Sandbox: https://test-payment.momo.vn
MOMO_API_ENDPOINT = if Rails.env.production?
  GlobalConfig.get("MOMO_API_ENDPOINT", "https://payment.momo.vn")
else
  GlobalConfig.get("MOMO_API_ENDPOINT", "https://test-payment.momo.vn")
end

# Log MoMo configuration status
Rails.logger.info("[MoMo] Configuration loaded - Partner Code: #{MOMO_PARTNER_CODE.present? ? 'Present' : 'Missing'}")
