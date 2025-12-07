import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "paymentElement",
    "submitButton",
    "defaultButtonIcon",
    "processingButtonIcon",
    "buttonText",
  ];
  static values = {
    stripePublishableKey: String,
    errorMessage: String,
  };

  connect() {
    this.stripe = Stripe(this.stripePublishableKeyValue);
    this.initializePaymentElement();
  }

  async initializePaymentElement() {
    try {
      // Get the account slug from the URL
      const accountSlug = window.location.pathname.split("/")[1];

      // Create a setup intent on the server
      const response = await fetch(
        `/${accountSlug}/billing/payment_methods/create_setup_intent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
              .content,
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // Check the content type to ensure we're getting JSON
      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        // If not JSON, get the text content for debugging
        const textContent = await response.text();
        console.error(
          "Received non-JSON response:",
          textContent.substring(0, 100) + "..."
        );
        throw new Error(
          "Server returned non-JSON response. Check console for details."
        );
      }

      const { client_secret, error } = await response.json();

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
            email: null,
          },
        },
        wallets: {
          applePay: "auto",
          googlePay: "auto",
          link: "never",
        },
      });

      // Mount the payment element
      this.paymentElement.mount(this.paymentElementTarget);

      // Handle form submission
      this.element.addEventListener("submit", this.handleSubmit.bind(this));
    } catch (error) {
      console.error("Error:", error);
      this.showError(this.errorMessageValue || "An unexpected error occurred.");
    }
  }

  async handleSubmit(event) {
    event.preventDefault();

    // Toggle the button to show a "processing" state
    this.toggleButtonState(true);

    try {
      // Get the account slug from the URL
      const accountSlug = window.location.pathname.split("/")[1];

      // Determine the return URL based on context
      let returnUrl;

      const result = await this.stripe.confirmSetup({
        elements: this.elements,
        confirmParams: {
          return_url:
            window.location.origin +
            `/${accountSlug}/billing/payment_methods/process_create_payment_method`,
        },
      });

      if (result.error) {
        this.toggleButtonState(false);
        this.showError(result.error.message);
      }
    } catch (error) {
      this.toggleButtonState(false);
      this.showError(this.errorMessageValue || "An unexpected error occurred.");
      console.error("Error:", error);
    }
  }

  toggleButtonState(isProcessing) {
    const submitButton = this.submitButtonTarget;
    const defaultButtonIcon = this.defaultButtonIconTarget;
    const processingButtonIcon = this.processingButtonIconTarget;
    const buttonText = this.buttonTextTarget;

    if (isProcessing) {
      submitButton.disabled = true;
      submitButton.classList.add("opacity-70");
      defaultButtonIcon.classList.add("hidden!");
      processingButtonIcon.classList.remove("hidden!");
      buttonText.textContent = submitButton.dataset.processingText;
    } else {
      submitButton.disabled = false;
      submitButton.classList.remove("opacity-70");
      defaultButtonIcon.classList.remove("hidden!");
      processingButtonIcon.classList.add("hidden!");
      buttonText.textContent = submitButton.dataset.defaultText;
    }
  }

  showError(message) {
    const messageDiv = document.getElementById("payment-message");
    messageDiv.textContent = message;
    messageDiv.classList.remove("hidden");
  }
}
