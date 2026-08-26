// Fastway — Apple Pay on the Web (Telr "Configuration 1" / Apple Pay JS).
//
// This module owns the browser ApplePaySession lifecycle and performs the two
// backend calls the flow needs:
//   1) onvalidatemerchant  -> POST {apiBase}{validatePath}   { validation_url }
//                             backend proxies to Telr and returns { merchant_session }.
//   2) onpaymentauthorized -> POST {apiBase}{chargePath}     { ...checkoutBody, apple_pay_token }
//                             backend charges via Telr remote.json and places the order.
//
// Dart calls window.fastwayApplePay.start(configJson) SYNCHRONOUSLY from the tap
// handler (Safari requires the session to be created inside the user gesture) and
// awaits a single JSON result string:
//   {"status":"success","orderNumber":"..."} | {"status":"cancelled"} |
//   {"status":"failure"|"error","message":"..."}
//
// The whole flow is debuggable in Safari Web Inspector — no Flutter interop in the
// network path. Auth headers + checkout body are passed in via the config.
(function () {
  'use strict';

  function post(url, headers, bodyObj) {
    return fetch(url, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(bodyObj),
    });
  }

  window.fastwayApplePay = {
    // True only on an Apple device whose Safari + Wallet can actually pay.
    available: function () {
      try {
        return !!(
          window.ApplePaySession &&
          ApplePaySession.supportsVersion &&
          ApplePaySession.supportsVersion(3) &&
          ApplePaySession.canMakePayments &&
          ApplePaySession.canMakePayments()
        );
      } catch (e) {
        return false;
      }
    },

    start: function (configJson) {
      return new Promise(function (resolve) {
        var settled = false;
        function done(obj) {
          if (!settled) { settled = true; resolve(JSON.stringify(obj)); }
        }

        var cfg;
        try { cfg = JSON.parse(configJson); }
        catch (e) { done({ status: 'error', message: 'bad_config' }); return; }

        var headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        if (cfg.authHeader)     headers['Authorization']   = cfg.authHeader;
        if (cfg.sessionId)      headers['X-Session-ID']    = cfg.sessionId;
        if (cfg.acceptLanguage) headers['Accept-Language'] = cfg.acceptLanguage;

        var request = {
          countryCode: cfg.countryCode || 'SA',
          currencyCode: cfg.currencyCode || 'SAR',
          merchantCapabilities: cfg.merchantCapabilities || ['supports3DS'],
          supportedNetworks: cfg.supportedNetworks || ['mada', 'visa', 'masterCard', 'amex'],
          total: { label: cfg.label || 'Fastway', amount: String(cfg.amount) },
        };

        var session;
        try { session = new ApplePaySession(3, request); }
        catch (e) { done({ status: 'error', message: 'session_create_failed' }); return; }

        // 1) Merchant validation — proxy Apple's one-time validationURL to our backend.
        session.onvalidatemerchant = function (event) {
          post(cfg.apiBase + cfg.validatePath, headers, { validation_url: event.validationURL })
            .then(function (r) { return r.ok ? r.json() : Promise.reject(r); })
            .then(function (data) {
              session.completeMerchantValidation(data.merchant_session || data);
            })
            .catch(function () {
              try { session.abort(); } catch (e) {}
              done({ status: 'error', message: 'merchant_validation_failed' });
            });
        };

        // 2) Payment authorized — send the encrypted token + checkout body to charge.
        session.onpaymentauthorized = function (event) {
          var body = Object.assign({}, cfg.checkoutBody, {
            apple_pay_token: event.payment.token,
          });
          post(cfg.apiBase + cfg.chargePath, headers, body)
            .then(function (r) {
              return r.json()
                .catch(function () { return {}; })
                .then(function (data) { return { ok: r.ok, data: data }; });
            })
            .then(function (res) {
              if (res.ok && res.data && res.data.status) {
                session.completePayment(ApplePaySession.STATUS_SUCCESS);
                done({ status: 'success', orderNumber: res.data.order_number });
              } else {
                session.completePayment(ApplePaySession.STATUS_FAILURE);
                done({
                  status: 'failure',
                  message: (res.data && res.data.message) || 'declined',
                });
              }
            })
            .catch(function () {
              try { session.completePayment(ApplePaySession.STATUS_FAILURE); } catch (e) {}
              done({ status: 'error', message: 'charge_failed' });
            });
        };

        session.oncancel = function () { done({ status: 'cancelled' }); };

        try { session.begin(); }
        catch (e) { done({ status: 'error', message: 'begin_failed' }); }
      });
    },
  };
})();
