module Checkout
  class MomoController < ApplicationController
    def complete
      order_id = params[:order_id]

      if order_id.blank?
        redirect_to "/", alert: "Invalid order ID"
        return
      end

      api_client = MomoApiClient.new
      begin
        response = api_client.query_transaction(order_id: order_id)
      rescue MomoApiClient::MomoApiError => e
        Rails.logger.error("[MoMo Checkout] Query failed: #{e.message}")
        redirect_to "/", alert: "Payment verification failed"
        return
      end

      if response[:resultCode] == 0
        # Check if order exists
        order = Order.find_by(external_id: order_id)

        if order
          # Capture payment successfully
          # Trigger ChargeEvent manually to ensure state is updated if IPN is delayed
          event = ChargeEvent.new
          event.charge_processor_id = MomoChargeProcessor.charge_processor_id
          event.charge_event_id = "momo_ipn_#{response[:transId]}"
          event.charge_id = order_id
          event.created_at = Time.current
          event.comment = "MoMo Redirect Verification: #{response[:message]}"
          event.type = ChargeEvent::TYPE_FUNDS_SETTLED

          # This will update the purchase state
          ChargeProcessor.handle_event(event)

          # Reload to get updated state
          order.reload
          purchase = order.successful_purchases.first

          if purchase
            redirect_to purchase.receipt_url, allow_other_host: true
          else
            # Fallback if purchases not found or not marked successful yet
            redirect_to "/", notice: "Payment successful. You will receive an email shortly."
          end
        else
          redirect_to "/", alert: "Order not found"
        end
      else
        redirect_to "/", alert: "Payment failed: #{response[:message]}"
      end
    end
  end
end
