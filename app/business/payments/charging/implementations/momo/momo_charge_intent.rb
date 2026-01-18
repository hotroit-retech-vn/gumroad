# frozen_string_literal: true

# Represents a MoMo charge intent (payment request pending user action)
class MomoChargeIntent
  attr_reader :id, :status, :pay_url, :deeplink, :qr_code_url, :amount

  # MoMo charge intent statuses
  STATUS_REQUIRES_ACTION = "requires_action"
  STATUS_SUCCESS = "succeeded"
  STATUS_FAILED = "failed"

  def initialize(momo_response)
    @id = momo_response[:orderId] || momo_response[:requestId]
    @pay_url = momo_response[:payUrl]
    @deeplink = momo_response[:deeplink]
    @qr_code_url = momo_response[:qrCodeUrl]
    @amount = momo_response[:amount]
    @result_code = momo_response[:resultCode]
    @message = momo_response[:message]

    @status = determine_status
  end

  def charge_processor_id
    MomoChargeProcessor.charge_processor_id
  end

  # Check if user action is required (redirect to MoMo)
  def requires_action?
    @status == STATUS_REQUIRES_ACTION
  end

  def success?
    @status == STATUS_SUCCESS
  end

  def failed?
    @status == STATUS_FAILED
  end

  # Get the URL to redirect user to complete payment
  def redirect_url
    @pay_url
  end

  # For mobile apps, use deeplink
  def mobile_redirect_url
    @deeplink
  end

  private
    def determine_status
      case @result_code.to_i
      when 0
        # Payment created successfully, awaiting user action
        STATUS_REQUIRES_ACTION
      else
        STATUS_FAILED
      end
    end
end
