import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "paymentElement",
    "paymentMessage",
    "paymentMethodId",
    "submitButton",
    "defaultButtonIcon",
    "processingButtonIcon",
    "buttonText",
  ];
  static values = {
    stripePublishableKey: String,
    priceSlug: String,
    isSubscription: Boolean,
    trialDays: Number,
    customerEmail: String,
    useExistingPaymentMethod: { type: Boolean, default: false },
    errorMessage: String,
  };

  connect() {
    // Called when the payment form is loaded
    this.stripe = Stripe(this.stripePublishableKeyValue);

    if (this.useExistingPaymentMethodValue) {
      // For existing payment methods, we just need to handle the form submission
      this.element.addEventListener(
        "submit",
        this.handleExistingPaymentMethodSubmit.bind(this)
      );
    } else {
      // For new payment methods, we need to initialize the payment element
      this.initializePaymentElement();
    }
  }

  async initializePaymentElement() {
    try {
      // Create a payment intent on the server
      const response = await fetch(this.element.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({
          price: this.priceSlugValue,
          is_subscription: this.isSubscriptionValue,
          trial_days: this.trialDaysValue,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // checkout_controller.rb sends the client_secret, error, and is_setup_intent
      const { client_secret, error, is_setup_intent } = await response.json();

      if (error) {
        this.showError(error);
        return;
      }

      // Initialize Elements with the client secret
      this.elements = this.stripe.elements({
        clientSecret: client_secret,
      });

      // Create the payment element
      this.paymentElement = this.elements.create("payment", {
        layout: "tabs",
        defaultValues: {
          billingDetails: {
            // Set this to this.customerEmailValue if you want to auto-opt-in customers to Stripe Link.
            email: null,
          },
        },
        // Set these to 'auto' to show (if platform supports it) or 'never' to always disable
        wallets: {
          applePay: "auto",
          googlePay: "auto",
          link: "never",
        },
      });

      // Mount the payment element
      this.paymentElement.mount(this.paymentElementTarget);

      // Store whether this is a setup intent for later use
      this.isSetupIntent = is_setup_intent;

      // Handle form submission
      this.element.addEventListener(
        "submit",
        this.handleNewPaymentMethodSubmit.bind(this)
      );
    } catch (error) {
      this.showError(this.errorMessageValue || "An unexpected error occurred.");
      console.error("Error:", error);
    } finally {
      this.toggleButtonState(false);

      // rails checkout_controller#process_checkout handles processing the purchase and redirecting user to a success page.
    }
  }

  async handleNewPaymentMethodSubmit(event) {
    // Called when the user clicks the "Subscribe" or "Purchase" button in the payment form.

    event.preventDefault();

    // Toggle the button to show a "processing" state
    this.toggleButtonState(true);

    try {
      let result;
      if (this.isSetupIntent) {
        result = await this.stripe.confirmSetup({
          elements: this.elements,
          confirmParams: {
            return_url: window.location.origin + "/checkout/process",
          },
        });
      } else {
        result = await this.stripe.confirmPayment({
          elements: this.elements,
          confirmParams: {
            return_url: window.location.origin + "/checkout/process",
          },
        });
      }

      if (result.error) {
        this.toggleButtonState(false);

        this.showError(result.error.message);
      }
    } catch (error) {
      this.toggleButtonState(false);

      this.showError(this.errorMessageValue || "An unexpected error occurred.");
      console.error("Error:", error);
    } finally {
      this.toggleButtonState(false);

      // rails checkout_controller#process_checkout handles processing the purchase and redirecting user to a success page.
    }
  }

  async handleExistingPaymentMethodSubmit(event) {
    // Called when the user clicks the "Subscribe" or "Purchase" button in the existing_payment_method partial.

    event.preventDefault();

    // Toggle the button to show a "processing" state
    this.toggleButtonState(true);

    try {
      // Get the payment method ID from the select field
      const paymentMethodId = this.paymentMethodIdTarget.value;

      // Create a payment intent on the server
      const response = await fetch(this.element.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({
          price: this.priceSlugValue,
          payment_method_id: paymentMethodId,
          is_subscription: this.isSubscriptionValue,
          trial_days: this.trialDaysValue,
        }),
      });

      if (!response.ok) {
        this.toggleButtonState(false);

        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const { client_secret, error, is_setup_intent } = await response.json();

      if (error) {
        this.toggleButtonState(false);

        this.showError(error);
        return;
      }

      // Redirect to the process_checkout endpoint with the correct parameter based on intent type
      if (is_setup_intent) {
        window.location.href = `/checkout/process?setup_intent=${client_secret}&redirect_status=succeeded`;
      } else {
        window.location.href = `/checkout/process?payment_intent=${client_secret}&redirect_status=succeeded`;
      }
    } catch (error) {
      this.toggleButtonState(false);

      this.showError(this.errorMessageValue || "An unexpected error occurred.");
      console.error("Error:", error);
    }
  }

  showError(message) {
    this.toggleButtonState(false);

    if (this.hasPaymentMessageTarget) {
      this.paymentMessageTarget.classList.remove("hidden");
      this.paymentMessageTarget.textContent = message;
    } else {
      console.error(message);
    }
  }

  toggleButtonState(processing) {
    var button = this.submitButtonTarget;
    var defaultText = button.dataset.defaultText;
    var processingText = button.dataset.processingText;

    if (processing) {
      button.disabled = true;
      button.classList.add("opacity-70");
      this.defaultButtonIconTarget.classList.add("hidden!");
      this.processingButtonIconTarget.classList.remove("hidden!");
      this.buttonTextTarget.textContent = processingText;
    } else {
      button.disabled = false;
      button.classList.remove("opacity-70");
      this.defaultButtonIconTarget.classList.remove("hidden!");
      this.processingButtonIconTarget.classList.add("hidden!");
      this.buttonTextTarget.textContent = defaultText;
    }
  }
}
