# frozen_string_literal: true

# Represents a chargeable payment source for MoMo
# MoMo uses redirect-based flow, so this mainly holds the order info
class MomoChargeable
  attr_reader :order_id, :amount, :return_url, :browser_guid

  def initialize(order_id:, amount:, return_url: nil, browser_guid: nil)
    @order_id = order_id
    @amount = amount
    @return_url = return_url
    @browser_guid = browser_guid
    @prepared = false
  end

  def charge_processor_id
    MomoChargeProcessor.charge_processor_id
  end

  def prepare!
    @prepared = true
    true
  end

  def prepared?
    @prepared
  end

  # MoMo doesn't use card-based funding
  def funding_type
    "wallet"
  end

  # MoMo doesn't have fingerprint like credit cards
  def fingerprint
    nil
  end

  def last4
    nil
  end

  def number_length
    nil
  end

  def visual
    "MoMo Wallet"
  end

  def expiry_month
    nil
  end

  def expiry_year
    nil
  end

  def zip_code
    nil
  end

  def card_type
    "momo"
  end

  def country
    "VN"
  end

  # MoMo doesn't support reusable tokens in the same way as Stripe
  def reusable_token!(_user)
    nil
  end

  # MoMo uses redirect-based flow, no charge params needed
  def momo_charge_params
    {
      order_id: @order_id,
      amount: @amount,
      return_url: @return_url
    }
  end

  def requires_mandate?
    false
  end
end
