# frozen_string_literal: true

# MoMo API Client for Vietnam Payment Gateway
# API Documentation: https://developers.momo.vn
class MomoApiClient
  API_VERSION = "v2"

  # Success result codes from MoMo
  SUCCESS_RESULT_CODE = 0
  PENDING_RESULT_CODE = 1000 # Transaction is in processing

  # Default timeout for API calls (30 seconds as recommended by MoMo)
  DEFAULT_TIMEOUT = 30

  class MomoApiError < StandardError
    attr_reader :result_code, :message

    def initialize(result_code, message)
      @result_code = result_code
      @message = message
      super("MoMo API Error [#{result_code}]: #{message}")
    end
  end

  def initialize
    @partner_code = GlobalConfig.get("MOMO_PARTNER_CODE")
    @access_key = GlobalConfig.get("MOMO_ACCESS_KEY")
    @secret_key = GlobalConfig.get("MOMO_SECRET_KEY")
    @api_endpoint = GlobalConfig.get("MOMO_API_ENDPOINT", default_endpoint)
  end

  # Create a payment request (captureWallet API)
  # Returns: Hash with payUrl, deeplink, qrCodeUrl for redirecting user
  def create_payment(order_id:, amount:, order_info:, return_url:, notify_url:, extra_data: "")
    request_id = SecureRandom.uuid
    request_type = "captureWallet"

    raw_signature = build_signature_string(
      accessKey: @access_key,
      amount: amount,
      extraData: extra_data,
      ipnUrl: notify_url,
      orderId: order_id,
      orderInfo: order_info,
      partnerCode: @partner_code,
      redirectUrl: return_url,
      requestId: request_id,
      requestType: request_type
    )

    signature = generate_signature(raw_signature)

    payload = {
      partnerCode: @partner_code,
      accessKey: @access_key,
      requestId: request_id,
      amount: amount.to_s,
      orderId: order_id,
      orderInfo: order_info,
      redirectUrl: return_url,
      ipnUrl: notify_url,
      extraData: extra_data,
      requestType: request_type,
      signature: signature,
      lang: "vi"
    }

    post_request("/#{API_VERSION}/gateway/api/create", payload)
  end

  # Query transaction status
  def query_transaction(order_id:, request_id: nil)
    request_id ||= SecureRandom.uuid

    raw_signature = build_signature_string(
      accessKey: @access_key,
      orderId: order_id,
      partnerCode: @partner_code,
      requestId: request_id
    )

    signature = generate_signature(raw_signature)

    payload = {
      partnerCode: @partner_code,
      accessKey: @access_key,
      requestId: request_id,
      orderId: order_id,
      signature: signature,
      lang: "vi"
    }

    post_request("/#{API_VERSION}/gateway/api/query", payload)
  end

  # Refund a transaction
  def refund(order_id:, trans_id:, amount:, description: "")
    request_id = SecureRandom.uuid

    raw_signature = build_signature_string(
      accessKey: @access_key,
      amount: amount,
      description: description,
      orderId: order_id,
      partnerCode: @partner_code,
      requestId: request_id,
      transId: trans_id
    )

    signature = generate_signature(raw_signature)

    payload = {
      partnerCode: @partner_code,
      accessKey: @access_key,
      requestId: request_id,
      orderId: order_id,
      transId: trans_id,
      amount: amount.to_s,
      description: description,
      signature: signature,
      lang: "vi"
    }

    post_request("/#{API_VERSION}/gateway/api/refund", payload)
  end

  # Verify IPN (Instant Payment Notification) signature from MoMo
  def verify_ipn_signature(params)
    received_signature = params[:signature]

    raw_signature = build_signature_string(
      accessKey: params[:accessKey],
      amount: params[:amount],
      extraData: params[:extraData],
      message: params[:message],
      orderId: params[:orderId],
      orderInfo: params[:orderInfo],
      orderType: params[:orderType],
      partnerCode: params[:partnerCode],
      payType: params[:payType],
      requestId: params[:requestId],
      responseTime: params[:responseTime],
      resultCode: params[:resultCode],
      transId: params[:transId]
    )

    expected_signature = generate_signature(raw_signature)
    ActiveSupport::SecurityUtils.secure_compare(received_signature.to_s, expected_signature)
  end

  private
    def default_endpoint
      Rails.env.production? ? "https://payment.momo.vn" : "https://test-payment.momo.vn"
    end

    def build_signature_string(**params)
      params.sort.map { |k, v| "#{k}=#{v}" }.join("&")
    end

    def generate_signature(raw_data)
      OpenSSL::HMAC.hexdigest("SHA256", @secret_key, raw_data)
    end

    def post_request(path, payload)
      uri = URI.parse("#{@api_endpoint}#{path}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = DEFAULT_TIMEOUT
      http.open_timeout = DEFAULT_TIMEOUT

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json; charset=UTF-8"
      request.body = payload.to_json

      response = http.request(request)
      result = JSON.parse(response.body, symbolize_names: true)

      Rails.logger.info("[MoMo API] Request to #{path}: #{payload.except(:signature).to_json}")
      Rails.logger.info("[MoMo API] Response: #{result.to_json}")

      if result[:resultCode] != SUCCESS_RESULT_CODE && result[:resultCode] != PENDING_RESULT_CODE
        raise MomoApiError.new(result[:resultCode], result[:message])
      end

      result
    rescue JSON::ParserError => e
      Rails.logger.error("[MoMo API] Failed to parse response: #{response.body}")
      raise MomoApiError.new(-1, "Invalid API response: #{e.message}")
    rescue Net::TimeoutError, Errno::ETIMEDOUT => e
      Rails.logger.error("[MoMo API] Request timeout: #{e.message}")
      raise MomoApiError.new(-2, "Request timeout: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[MoMo API] Request failed: #{e.message}")
      raise MomoApiError.new(-3, "Request failed: #{e.message}")
    end
end
