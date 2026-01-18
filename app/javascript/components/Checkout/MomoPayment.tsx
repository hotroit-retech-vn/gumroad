import * as React from "react";
import { useOnChangeSync } from "$app/components/useOnChange";
import { Button } from "$app/components/Button";
import { PaymentMethodRadio } from "$app/components/Checkout/PaymentForm";
import { useState, isSubmitDisabled, usePayLabel } from "$app/components/Checkout/payment";
import { getPaymentMethodResult, NewMomoSelectedPaymentMethod } from "$app/data/payment_method_result";

export const MomoPayment = ({ className }: { className?: string }) => {
  const [state, dispatch] = useState();
  const payLabel = usePayLabel();

  // Registration
  React.useEffect(() => {
    // Check if supported. `state.products` should have `supportsMomo`.
    // Assuming product_common in json includes supports_momo, which maps to supportsMomo in camelCase?
    // Let's verify type definition in payment.ts. Yes, `supportsMomo: boolean`.
    const supported = state.products.some(p => p.supportsMomo);
    if (!supported) return;

    dispatch({
      type: "add-payment-method",
      paymentMethod: {
        type: "momo",
        button: (
          <PaymentMethodRadio paymentMethod="momo">
             <div className="flex w-full flex-col items-center justify-center gap-2 self-center">

                <img src="/images/momo_icon.png" alt="MoMo" className="w-5 h-5" />
                <h4 className="text-center">MoMo</h4>
             </div>
          </PaymentMethodRadio>
        )
      }
    });
  }, [state.products]);

  useOnChangeSync(() => {
    if (state.paymentMethod !== "momo") return;

    // Explicitly start payment if offering, similar to others?
    // Actually, generic `offer` sets `offering`.
    // Validating -> starting is handled by component?
    // BraintreePayPal listens to `starting`?
    // MomoPayment just needs to dispatch 'start-payment' if offering, to move to 'starting'?
    // Wait, BraintreePayPal doesn't do that. It calls tokenize when starting.

    // If I look at PayPal component again:
    // if (state.status.type === "validating") dispatch({ type: "start-payment" });

    // So something must transition offering -> validating.
    // Line 118: `type: "validate"` -> `state.status = { type: "input", errors } : { type: "validating" }`

    // Who dispatches `validate`?
    // Maybe `NativePayPal` or `BraintreePayPal` calls `dispatch({ type: "offer" })`.
    // Reducer `offer`: `state.status = ... : { type: "offering" }`.

    // So we are stuck in Offering.
    // UNLESS `PaymentForm` generic effect handles offering!
    // I searched and found nothing.

    // But `CreditCard` uses `offer`.
    // `state.status` becomes `offering`.
    // Who listens?

    // Maybe I should just check `PaymentForm.tsx` line 520~550 where `PaymentMethodRadio` is defined.
    // Maybe it's handled in `CreditCard` component?

    if (state.status.type === "offering") {
         dispatch({ type: "start-payment" });
    }

    if (state.status.type === "starting") {
        const selected: NewMomoSelectedPaymentMethod = { type: "momo" };
        getPaymentMethodResult(selected).then(paymentMethod => {
             dispatch({ type: "set-payment-method", paymentMethod });
        });
    }
  }, [state.status.type]);

  if (state.paymentMethod !== "momo") return null;

  return (
    <div className={className}>
       <Button
         className="button-momo grow"
         onClick={() => dispatch({ type: "offer" })}
         disabled={isSubmitDisabled(state)}
       >
          {payLabel}
       </Button>
    </div>
  );
};
