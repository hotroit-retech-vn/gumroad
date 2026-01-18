import * as React from "react";

import { Icon } from "$app/components/Icons";
import { Alert } from "$app/components/ui/Alert";

export type MoMoConnect = {
  show_momo_connect: boolean;
  momo_enabled: boolean;
  supported_countries: string[];
};

const MoMoConnectSection = ({
  momoConnect,
  isFormDisabled,
}: {
  momoConnect: MoMoConnect;
  isFormDisabled: boolean;
}) => {
  if (!momoConnect.show_momo_connect) {
    return null;
  }

  return (
    <section className="p-4! md:p-8!">
      <header>
        <h2>MoMo</h2>
        <span className="text-muted">Vietnam E-Wallet</span>
        {isFormDisabled}
      </header>
      <div className="flex flex-col gap-4">
        {momoConnect.momo_enabled ? (
          <>
            <div className="grid gap-8">
              <fieldset>
                <legend>
                  <label>MoMo Status</label>
                </legend>
                <div className="input input-wrapper">
                  <div className="fake-input">Enabled for Vietnam customers</div>
                  <Icon name="solid-check-circle" className="text-success" />
                </div>
              </fieldset>
            </div>
            <Alert variant="info">
              MoMo payments are automatically enabled for your account because your country is set to Vietnam.
              Customers from Vietnam will see MoMo as a payment option at checkout.
            </Alert>
          </>
        ) : (
          <>
            <p>
              MoMo is Vietnam's leading e-wallet platform with over 30 million users.
              Enable MoMo to accept payments from Vietnamese customers.
            </p>
            <p>
              Currently available in: {momoConnect.supported_countries.join(", ")}.
            </p>
            <Alert variant="info">
              To enable MoMo payments, your account country must be set to Vietnam.
              You can update your country in the account details section above.
            </Alert>
          </>
        )}
      </div>
    </section>
  );
};

export default MoMoConnectSection;
