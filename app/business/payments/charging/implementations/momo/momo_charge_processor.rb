# frozen_string_literal: true

# MoMo Charge Processor for Vietnam e-wallet payments
# Implements the ChargeProcessor interface for MoMo integration
class MomoChargeProcessor
  DISPLAY_NAME = "MoMo"

  # Valid transaction statuses
  VALID_TRANSACTION_STATUSES = %w(success pending).freeze

  def self.charge_processor_id
    "momo"
  end

  def merchant_migrated?(_merchant_account)
    false
  end

  # Build a chargeable from request parameters
  # MoMo uses redirect flow, so we need order_id and amount from params
  def get_chargeable_for_params(params, gumroad_guid)
    return nil unless params[:payment_method] == "momo" || params[:momo_payment].present?

    MomoChargeable.new(
      order_id: params[:order_id] || SecureRandom.uuid,
      amount: params[:amount_cents],
      return_url: params[:momo_return_url],
      browser_guid: gumroad_guid
    )
  end

  # Build a chargeable from stored data (for recurring payments - not supported by MoMo)
  def get_chargeable_for_data(_reusable_token, _payment_method_id, _fingerprint,
                              _setup_intent_id, _payment_intent_id,
                              _last4, _number_length, _visual, _expiry_month, _expiry_year,
                              _card_type, _country, _zip_code = nil, merchant_account: nil)
    # MoMo doesn't support stored payment methods for recurring charges
    nil
  end

  # Search for a charge by purchase reference
  def search_charge(purchase:)
    return nil unless purchase.charge_processor_id == self.class.charge_processor_id

    order_id = purchase.external_id
    api_client = MomoApiClient.new

    begin
      response = api_client.query_transaction(order_id: order_id)
      MomoCharge.new(response)
    rescue MomoApiClient::MomoApiError => e
      Rails.logger.error("[MoMo] Failed to search charge: #{e.message}")
      nil
    end
  end

  # Get charge by ID (order_id in MoMo's case)
  def get_charge(charge_id, merchant_account: nil)
    api_client = MomoApiClient.new

    response = api_client.query_transaction(order_id: charge_id)
    MomoCharge.new(response)
  rescue MomoApiClient::MomoApiError => e
    Rails.logger.error("[MoMo] Failed to get charge: #{e.message}")
    raise ChargeProcessorError.new("Failed to get MoMo charge: #{e.message}")
  end

  def get_charge_object(charge_response)
    MomoCharge.new(charge_response)
  end

  # Get charge intent (not directly applicable to MoMo's flow)
  def get_charge_intent(payment_intent_id, merchant_account: nil)
    # Query the transaction status
    api_client = MomoApiClient.new
    response = api_client.query_transaction(order_id: payment_intent_id)

    MomoChargeIntent.new(response)
  rescue MomoApiClient::MomoApiError => e
    Rails.logger.error("[MoMo] Failed to get charge intent: #{e.message}")
    nil
  end

  # MoMo doesn't support setup intents
  def get_setup_intent(_setup_intent_id, merchant_account: nil)
    nil
  end

  # MoMo doesn't support setup for future charges
  def setup_future_charges!(_merchant_account, _chargeable, mandate_options: nil)
    raise ChargeProcessorNotSupportedError.new("MoMo does not support recurring payments setup")
  end

  # Create a payment intent (payment request in MoMo's terminology)
  # This creates a payment URL that the user needs to be redirected to
  def create_payment_intent_or_charge!(merchant_account, chargeable, amount_cents, _amount_for_gumroad_cents, reference,
                                       description, metadata: nil, statement_description: nil,
                                       transfer_group: nil, off_session: true, setup_future_charges: false, mandate_options: nil)
    # MoMo doesn't support off-session charges
    if off_session
      raise ChargeProcessorNotSupportedError.new("MoMo requires on-session user confirmation")
    end

    api_client = MomoApiClient.new
    order_id = reference || SecureRandom.uuid

    # Get return and notify URLs
    return_url = chargeable.return_url || default_return_url(order_id)
    notify_url = momo_ipn_url

    # Create extra data with metadata
    extra_data = metadata.present? ? Base64.strict_encode64(metadata.to_json) : ""

    response = api_client.create_payment(
      order_id: order_id,
      amount: amount_cents, # MoMo expects amount in VND (no decimal)
      order_info: description || "Payment for #{reference}",
      return_url: return_url,
      notify_url: notify_url,
      extra_data: extra_data
    )

    MomoChargeIntent.new(response)
  rescue MomoApiClient::MomoApiError => e
    Rails.logger.error("[MoMo] Failed to create payment: #{e.message}")
    raise ChargeProcessorCardError.new("MoMo payment creation failed: #{e.message}")
  end

  # MoMo doesn't have separate confirm step - payment is confirmed when user completes on MoMo app
  def confirm_payment_intent!(_merchant_account, charge_intent_id)
    get_charge_intent(charge_intent_id)
  end

  # Cancel is not directly supported - payments expire automatically
  def cancel_payment_intent!(_merchant_account, _charge_intent_id)
    # MoMo payments expire after a timeout (typically 15 minutes)
    # No explicit cancel API available
    true
  end

  def cancel_setup_intent!(_merchant_account, _setup_intent_id)
    # MoMo doesn't support setup intents
    true
  end

  # Refund a charge
  def refund!(charge_id, amount_cents: nil, merchant_account: nil, reverse_transfer: true, is_for_fraud: nil, **_args)
    api_client = MomoApiClient.new

    # First, get the original transaction to get the trans_id
    original_charge = get_charge(charge_id)

    refund_amount = amount_cents || original_charge.flow_of_funds&.issued_amount&.cents

    response = api_client.refund(
      order_id: "refund_#{charge_id}_#{Time.current.to_i}",
      trans_id: original_charge.trans_id,
      amount: refund_amount,
      description: is_for_fraud ? "Refund due to fraud" : "Customer refund"
    )

    # Return a charge object representing the refund
    MomoCharge.new(response.merge(amount: refund_amount))
  rescue MomoApiClient::MomoApiError => e
    Rails.logger.error("[MoMo] Failed to refund: #{e.message}")
    raise ChargeProcessorError.new("MoMo refund failed: #{e.message}")
  end

  # Fight chargeback - not applicable to MoMo
  def fight_chargeback(_charge_id, _dispute_evidence, merchant_account: nil)
    # MoMo doesn't have a dispute mechanism like credit cards
    nil
  end

  # MoMo holds funds directly - transferred to merchant's MoMo wallet
  def holder_of_funds(_merchant_account)
    HolderOfFunds::GUMROAD
  end

  # Transaction URL for viewing on MoMo dashboard
  def self.transaction_url(charge_id)
    # MoMo doesn't have a public transaction URL
    nil
  end

  def transaction_url(charge_id)
    self.class.transaction_url(charge_id)
  end

  # Handle MoMo IPN (webhook) events
  def self.handle_momo_ipn(params)
    api_client = MomoApiClient.new

    # Verify the signature
    unless api_client.verify_ipn_signature(params)
      Rails.logger.error("[MoMo IPN] Invalid signature")
      return false
    end

    result_code = params[:resultCode].to_i
    order_id = params[:orderId]
    trans_id = params[:transId]

    # Create a charge event
    event = ChargeEvent.new
    event.charge_processor_id = charge_processor_id
    event.charge_event_id = "momo_ipn_#{trans_id}"
    event.charge_id = order_id
    event.created_at = Time.current
    event.comment = "MoMo IPN: #{params[:message]}"

    if result_code == 0
      event.type = ChargeEvent::TYPE_FUNDS_SETTLED
      Rails.logger.info("[MoMo IPN] Payment successful for order #{order_id}")
    else
      event.type = ChargeEvent::TYPE_INFORMATIONAL
      Rails.logger.info("[MoMo IPN] Payment failed for order #{order_id}: #{params[:message]}")
    end

    ChargeProcessor.handle_event(event)
    true
  end

  private
    def default_return_url(order_id)
      "#{UrlService.domain_with_protocol}/checkout/momo/complete?order_id=#{order_id}"
    end

    def momo_ipn_url
      "#{UrlService.domain_with_protocol}/momo-webhook"
    end
end
