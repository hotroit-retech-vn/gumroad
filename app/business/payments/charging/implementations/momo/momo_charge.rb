# frozen_string_literal: true

# Represents a MoMo charge/transaction
class MomoCharge < BaseProcessorCharge
  # MoMo transaction status constants
  STATUS_SUCCESS = "success"
  STATUS_PENDING = "pending"
  STATUS_FAILED = "failed"

  attr_accessor :trans_id, :pay_type, :order_info, :response_time, :message

  def initialize(momo_response)
    self.charge_processor_id = MomoChargeProcessor.charge_processor_id
    return if momo_response.nil?

    self.id = momo_response[:orderId]
    self.trans_id = momo_response[:transId]
    self.pay_type = momo_response[:payType]
    self.order_info = momo_response[:orderInfo]
    self.response_time = momo_response[:responseTime]
    self.message = momo_response[:message]

    # Map MoMo result codes to status
    self.status = map_result_code_to_status(momo_response[:resultCode])
    self.refunded = false
    self.disputed = false

    # MoMo doesn't charge separate fees like Stripe
    self.fee = 0
    self.fee_currency = "VND"

    # Build flow of funds
    if momo_response[:amount].present?
      self.flow_of_funds = build_flow_of_funds(momo_response[:amount].to_i)
    end
  end

  private
    def map_result_code_to_status(result_code)
      case result_code.to_i
      when 0
        STATUS_SUCCESS
      when 1000
        STATUS_PENDING
      else
        STATUS_FAILED
      end
    end

    def build_flow_of_funds(amount_cents)
      issued_amount = FlowOfFunds::Amount.new(currency: "VND", cents: amount_cents)
      settled_amount = FlowOfFunds::Amount.new(currency: "VND", cents: amount_cents)
      gumroad_amount = issued_amount

      FlowOfFunds.new(
        issued_amount:,
        settled_amount:,
        gumroad_amount:,
        merchant_account_gross_amount: nil,
        merchant_account_net_amount: nil
      )
    end
end
