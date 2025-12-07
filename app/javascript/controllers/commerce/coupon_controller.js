import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "input",
    "fieldValidationMessage",
    "fieldCheckingMessage",
    "fieldSuccessMessage",
    "fieldFailureMessage",
  ];
  static values = {
    context: String,
    urlCoupon: String,
    success: Boolean, // Whether the coupon is valid
    percentOff: Number, // From Stripe coupon settings, has a value if the coupon is a percentage discount.
    amountOff: Number, // From Stripe coupon settings, has a value if the coupon is a fixed amount discount.
    successMessage: String, // (set in promo code metadata, success_message) The short phrase show as feedback when the coupon is valid
    successDescription: String, // (set in promo code metadata, success_description) A short sentence (shown in the purchase details side panel) describing the coupon that's been successfully applied.
    customPriceText: String, // (set in promo code metadata, custom_price_text) Text to display below the crossed out price when the coupon is successfully applied. Leave blank to auto-generate this text.
    customAppendText: String, // (set in promo code metadata, custom_append_text) Text to display after the discounted price when the coupon is successfully applied. Leave blank if it's not different from the original price append text.
    roundDirection: String, // If set (to 'up' or 'down'), the discounted price will be rounded to the nearest whole number.
    couponAppliedMessage: String,
    invalidCouponMessage: String,
    errorCheckingCouponMessage: String,
  };

  DEFAULT_CLASSES = [
    "bg-amber-100",
    "dark:bg-amber-900",
    "text-amber-600",
    "dark:text-amber-400",
  ];
  SUCCESS_CLASSES = [
    "bg-green-100",
    "dark:bg-green-900",
    "text-green-600",
    "dark:text-green-400",
  ];
  FAILURE_CLASSES = [
    "bg-red-100",
    "dark:bg-red-900",
    "text-red-600",
    "dark:text-red-400",
  ];
  ERROR_CLASSES = [
    "bg-red-100",
    "dark:bg-red-900",
    "text-red-600",
    "dark:text-red-400",
  ];

  connect() {
    // There are 3 separate places where the coupon controller is instantiated:
    //   1. On the plans selection page
    //   2. Checkout page: On the coupon input field
    //   3. Checkout page: the purchase details partial

    // Checkout page:
    //   Whichever coupon controller instance is the first to successfully validate the coupon will set the coupon's success values to data attributes
    //   set on the parent div.checkout-container element, so that we can access those at any point in the checkout process,
    //   without needing to re-validate the coupon (unless the coupon field is changed, in which case we do re-validate).

    // Which instance of the coupon controller is this?
    const context = this.contextValue;

    // Set the parent element on the checkout page
    const parentElement = this.element.closest(".checkout-container");

    // Check to see if we already have coupon success data stored on the parent element (on checkout page)
    if (parentElement && parentElement.dataset.success === "true") {
      const successData = {
        percentOff: parentElement.dataset.percentOff,
        amountOff: parentElement.dataset.amountOff,
        successMessage: parentElement.dataset.successMessage,
        successDescription: parentElement.dataset.successDescription,
        customPriceText: parentElement.dataset.customPriceText,
        customAppendText: parentElement.dataset.customAppendText,
      };

      this.handleSuccess(context, successData);
    } else {
      // We don't yet have a coupon success...

      // Check to see if a coupon code was passed in the URL
      if (this.urlCouponValue) {
        // Yes, a coupon code was passed in the URL, so we need to validate it

        if (this.contextValue === "field") {
          // Show the coupon field
          this.element.classList.remove("hidden");

          if (this.urlCouponValue !== "true") {
            // Put the coupon field into a loading state, unless the 'coupon' URL parameter is 'true' (in which case we just show the blank coupon field)
            this.fieldLoadingState();
          }
        }

        // Validate the coupon
        //   First parameter is event, which is null for this initial connection
        //   Second parameter is context, which is 'field', 'purchaseDetails', or 'plans'
        this.validateCoupon(null, context);
      }
    }
  }

  validateCoupon(event, context) {
    // Ping our backend to see if the coupon is valid

    let couponCode;
    let inputFieldChanged = false;

    if (event && event.type === "keyup") {
      // If user typed into the coupon field, then the conext is 'field' and the coupon code is the value of the input field
      context = "field";
      couponCode = this.inputTarget.value.trim();
      inputFieldChanged = true;
    } else if (!event) {
      // This was not triggered by user typing into the coupon field...
      // context is assumed to have been passed in as a parameter (either 'field' or 'purchaseDetails')

      // Get the coupon code from the URL parameter 'coupon', if it exists
      couponCode = this.urlCouponValue;
    }

    // If the coupon code is blank, or if it's the word 'true', don't validate the coupon
    // In the case of 'true', we simply show the coupon field (blank) but don't validate until the user types in a coupon code.
    if (couponCode === "true" || !couponCode) {
      console.log("couponCode is blank or true, so not validating");
      return;
    }

    // Make request to validate coupon
    const makeRequest = () => {
      fetch(`/checkout/validate_coupon?code=${encodeURIComponent(couponCode)}`)
        .then((response) => response.json())
        .then((data) => {
          if (data.valid) {
            const successData = {
              percentOff: data.percent_off,
              amountOff: data.amount_off,
              successMessage:
                data.success_message ||
                this.couponAppliedMessageValue ||
                "Coupon applied!",
              successDescription: data.success_description,
              customPriceText: data.custom_price_text,
              customAppendText: data.custom_append_text,
            };
            this.handleSuccess(context, successData);
          } else {
            this.handleFailure(context, data.failure_message);
          }
        })
        .catch((error) => {
          if (context === "field") {
            this.fieldErrorState();
          } else if (context === "purchaseDetails") {
            this.resetPurchaseDetails();
          }
        });
    };

    if (inputFieldChanged) {
      this.fieldLoadingState();
      this.resetPurchaseDetails();
      setTimeout(makeRequest, 500);
    } else {
      makeRequest();
    }
  }

  handleSuccess(context, successData) {
    if (context === "plans") {
      // This is the plans page
      this.plansSuccessState(successData);
    } else {
      // This is the checkout page
      if (context === "field") {
        this.fieldSuccessState(successData);
      }
      this.purchaseDetailsSuccessState(successData);
    }
  }

  handleFailure(context, failureMessage) {
    if (context === "plans") {
      // This is the plans page
    } else {
      // This is the checkout page

      // Nullify the coupon success data on the parent element (if any)
      const parentElement = this.element.closest(".checkout-container");
      parentElement.dataset.success = "false";
      parentElement.dataset.successMessage = "";
      parentElement.dataset.successDescription = "";
      parentElement.dataset.percentOff = null;
      parentElement.dataset.amountOff = null;
      parentElement.dataset.customPriceText = null;

      if (context === "field") {
        this.fieldFailureState(failureMessage);
      }
      this.resetPurchaseDetails();
    }
  }

  fieldLoadingState() {
    console.log("fieldLoadingState");
    this.fieldValidationMessageTarget.classList.remove("hidden");
    this.fieldValidationMessageTarget.classList.add(...this.DEFAULT_CLASSES);
    this.fieldValidationMessageTarget.classList.remove(
      ...this.SUCCESS_CLASSES,
      ...this.FAILURE_CLASSES
    );
    this.fieldCheckingMessageTarget.classList.remove("hidden");
    this.fieldSuccessMessageTarget.classList.add("hidden");
    this.fieldFailureMessageTarget.classList.add("hidden");
  }

  fieldSuccessState(successData) {
    const message =
      successData.successMessage ||
      this.couponAppliedMessageValue ||
      "Coupon applied!";
    this.fieldValidationMessageTarget.classList.remove("hidden");
    this.fieldValidationMessageTarget.classList.add(...this.SUCCESS_CLASSES);
    this.fieldValidationMessageTarget.classList.remove(...this.FAILURE_CLASSES);
    this.fieldSuccessMessageTarget.classList.remove("hidden");
    this.fieldFailureMessageTarget.classList.add("hidden");
    this.fieldCheckingMessageTarget.classList.add("hidden");
    this.fieldSuccessMessageTarget.textContent = message;
  }

  fieldFailureState(failureMessage) {
    const message =
      failureMessage || this.invalidCouponMessageValue || "Invalid coupon";
    this.fieldValidationMessageTarget.classList.remove("hidden");
    this.fieldValidationMessageTarget.classList.add(...this.FAILURE_CLASSES);
    this.fieldValidationMessageTarget.classList.remove(...this.SUCCESS_CLASSES);
    this.fieldSuccessMessageTarget.classList.add("hidden");
    this.fieldFailureMessageTarget.classList.remove("hidden");
    this.fieldCheckingMessageTarget.classList.add("hidden");
    this.fieldFailureMessageTarget.textContent = message;
  }

  fieldErrorState(failureMessage) {
    this.fieldValidationMessageTarget.classList.remove("hidden");
    this.fieldValidationMessageTarget.classList.add(...this.ERROR_CLASSES);
    this.fieldValidationMessageTarget.classList.remove(...this.SUCCESS_CLASSES);
    this.fieldValidationMessageTarget.classList.remove(...this.FAILURE_CLASSES);
    this.fieldCheckingMessageTarget.classList.add("hidden");
    this.fieldSuccessMessageTarget.classList.add("hidden");
    this.fieldFailureMessageTarget.classList.add("hidden");
    this.fieldCheckingMessageTarget.textContent =
      failureMessage ||
      this.errorCheckingCouponMessageValue ||
      "Error checking coupon";
  }

  purchaseDetailsSuccessState(successData) {
    // Locate the elements in the _purchase_details partial
    const purchaseDetailsContainer = document.getElementById(
      "purchase-details-container"
    );
    const displayPriceContainer =
      purchaseDetailsContainer.querySelector("#display-price");
    const currencySymbol =
      displayPriceContainer.querySelector(".currency-symbol");
    const priceAmount = displayPriceContainer.querySelector(".price-amount");
    const originalPriceText = priceAmount.textContent.trim();
    const priceAppendText =
      displayPriceContainer.querySelector(".price-append-text");

    // Clone the display price element
    const discountedDisplayPriceContainer =
      displayPriceContainer.cloneNode(true);
    const discountedPriceAmount =
      discountedDisplayPriceContainer.querySelector(".price-amount");
    const discountedCurrencySymbol =
      discountedDisplayPriceContainer.querySelector(".currency-symbol");
    const discountedPriceAppendText =
      discountedDisplayPriceContainer.querySelector(".price-append-text");
    discountedDisplayPriceContainer.classList.add(
      "discounted-price-container",
      "mt-[3px]",
      "text-emerald-500!",
      "dark:text-emerald-400!"
    );

    if (successData.customPriceText) {
      // The coupon has a custom price text, so we insert it into the display price element
      discountedPriceAmount.textContent = successData.customPriceText;
      discountedCurrencySymbol.remove();
      if (discountedPriceAppendText) {
        discountedPriceAppendText.remove();
      }
    } else {
      // There is no custom discounted price text, so we will calculate and generate it
      const discountedPriceText = this.generateDiscountedPriceText(
        originalPriceText,
        successData.percentOff,
        successData.amountOff
      );
      discountedPriceAmount.textContent = discountedPriceText;
      if (successData.customAppendText) {
        discountedPriceAppendText.textContent = successData.customAppendText;
        discountedPriceAppendText.classList.add("pl-[2px]");
      }

      // Display the discounted price
      if (
        !purchaseDetailsContainer.querySelector(".discounted-price-container")
      ) {
        displayPriceContainer.insertAdjacentElement(
          "afterend",
          discountedDisplayPriceContainer
        );
      }

      // Cross out the current price
      currencySymbol.classList.add("line-through");
      priceAmount.classList.add("line-through");
      if (priceAppendText) {
        priceAppendText.classList.add("line-through");
      }

      // Show the coupon details container
      const couponDetails =
        purchaseDetailsContainer.querySelector("#coupon-details");
      if (successData.successMessage) {
        const couponDetailsHeadline = couponDetails.querySelector(
          "#coupon-details-headline"
        );
        couponDetailsHeadline.textContent = successData.successMessage;
      }
      if (successData.successDescription) {
        const couponDetailsDescription = couponDetails.querySelector(
          "#coupon-details-description"
        );
        couponDetailsDescription.classList.remove("hidden");
        couponDetailsDescription.textContent = successData.successDescription;
      }
      couponDetails.classList.remove("hidden");
    }
  }

  resetPurchaseDetails() {
    // Locate the elements in the _purchase_details partial
    const purchaseDetailsContainer = document.getElementById(
      "purchase-details-container"
    );

    // Hide the coupon details
    const couponDetails =
      purchaseDetailsContainer.querySelector("#coupon-details");
    if (couponDetails) {
      couponDetails.classList.add("hidden");
    }

    // Remove the discounted price
    const discountedPriceContainer = purchaseDetailsContainer.querySelector(
      ".discounted-price-container"
    );
    if (discountedPriceContainer) {
      discountedPriceContainer.remove();
    }

    // Restore the original price
    const displayPriceContainer =
      purchaseDetailsContainer.querySelector("#display-price");
    const currencySymbol =
      displayPriceContainer.querySelector(".currency-symbol");
    const priceAmount = displayPriceContainer.querySelector(".price-amount");
    const priceAppendText =
      displayPriceContainer.querySelector(".price-append-text");
    currencySymbol.classList.remove("line-through");
    priceAmount.classList.remove("line-through");
    if (priceAppendText) {
      priceAppendText.classList.remove("line-through");
    }
  }

  plansSuccessState(successData) {
    const planPriceContainers = document.querySelectorAll(
      ".plan-price-container"
    );

    planPriceContainers.forEach((container) => {
      const planContainer = container.closest(
        "[data-commerce--plans-target='plan']"
      );
      const planPriceDisplay = container.querySelector(".plan-price-display");
      const priceAmountElement = container.querySelector(".price-amount");
      const originalPriceText = priceAmountElement.textContent.trim();

      // Ensure the discounted price isn't alrady shown and if not, proceed to showing it.
      const discountedPriceContainer = planContainer.querySelector(
        ".discounted-price-container"
      );
      if (!discountedPriceContainer) {
        // duplicate the plan price display and display it as the discounted price
        const discountedPlanPriceContainer = container.cloneNode(true);
        const discountedTextColorClasses = [
          "text-primary-500!",
          "dark:text-primary-400!",
        ];
        const discountedPriceAmount =
          discountedPlanPriceContainer.querySelector(".price-amount");
        const discountedCurrencySymbol =
          discountedPlanPriceContainer.querySelector(".currency-symbol");
        const discountedPriceAppendText =
          discountedPlanPriceContainer.querySelector(".price-append-text");
        discountedPriceAmount.classList.add(...discountedTextColorClasses);
        if (successData.customPriceText) {
          // The Stripe coupon promo code has custom_price_text, so we'll display that instead of the calculated discounted price
          discountedPriceAmount.textContent = successData.customPriceText;
          discountedCurrencySymbol.remove();
          if (discountedPriceAppendText) {
            discountedPriceAppendText.remove();
          }
        } else {
          const discountedPriceText = this.generateDiscountedPriceText(
            originalPriceText,
            successData.percentOff,
            successData.amountOff
          );
          discountedPlanPriceContainer.classList.add(
            "discounted-price-container",
            "mt-[3px]"
          );
          discountedPriceAmount.textContent = discountedPriceText;
          discountedCurrencySymbol.classList.add(...discountedTextColorClasses);
          if (discountedPriceAppendText) {
            discountedPriceAppendText.classList.add(
              ...discountedTextColorClasses
            );
            if (successData.customAppendText) {
              discountedPriceAppendText.textContent =
                successData.customAppendText;
            }
          }
        }

        // Remove the price note from the discounted plan price container (we'll leave it on the original price container)
        const discountedPriceNote =
          discountedPlanPriceContainer.querySelector(".price-note");
        if (discountedPriceNote) {
          discountedPriceNote.remove();
        }
        container.insertAdjacentElement(
          "afterend",
          discountedPlanPriceContainer
        );

        // Modify styling of the original price
        const originalCurrencySymbol =
          planPriceDisplay.querySelector(".currency-symbol");
        const originalPriceAmount =
          planPriceDisplay.querySelector(".price-amount");
        const originalPriceAppendText =
          planPriceDisplay.querySelector(".price-append-text");
        const originalPriceClasses = [
          "text-2xl",
          "md:text-2xl",
          "line-through",
          "opacity-50",
        ];
        if (originalCurrencySymbol) {
          originalCurrencySymbol.classList.add(...originalPriceClasses);
        }
        if (originalPriceAmount) {
          originalPriceAmount.classList.add(...originalPriceClasses);
        }
        if (originalPriceAppendText) {
          originalPriceAppendText.classList.add(...originalPriceClasses);
        }
      }
    });
  }

  generateDiscountedPriceText(
    originalPriceText,
    percentOffData = null,
    amountOffData = null
  ) {
    // Extract just the numeric price from the text that may include currency symbol and additional text
    // This regex matches a number with optional decimal places and optional comma separators
    console.log("originalPriceText", originalPriceText);
    const priceMatch = originalPriceText.match(/[\d,]+(\.\d+)?/);

    if (!priceMatch) {
      console.error("Could not extract price from text:", originalPriceText);
      return;
    }

    const originalPrice = parseFloat(priceMatch[0].replace(/,/g, ""));

    // Check if we have discount information
    const percentOff = percentOffData;
    const amountOff = amountOffData;

    if (percentOff === null && amountOff === null) {
      return;
    }

    // Calculate the discounted price based on the coupon type
    let discountedPrice;

    if (percentOff !== null) {
      // Percentage discount
      discountedPrice = originalPrice * (1 - percentOff / 100);
    } else if (amountOff !== null) {
      // Fixed amount discount (in cents)
      discountedPrice = originalPrice - amountOff / 100;
    } else {
      // If no discount information is provided, don't update the price
      return;
    }

    // Round the discounted price to the nearest whole number, if the roundDirectionValue is set
    if (this.hasRoundDirectionValue) {
      if (this.roundDirectionValue === "up") {
        discountedPrice = Math.ceil(discountedPrice);
      } else if (this.roundDirectionValue === "down") {
        discountedPrice = Math.floor(discountedPrice);
      }
    }

    // Format the discounted price to 2 or 0 decimal places, depending on whether it should show cents or not
    let formattedDiscountedPrice;
    if (discountedPrice % 1 === 0) {
      // No decimals needed
      formattedDiscountedPrice = discountedPrice.toFixed(0);
    } else {
      // Always show 2 decimal places
      formattedDiscountedPrice = discountedPrice.toFixed(2);
    }

    // Format the number with commas
    const formattedWithCommas = formattedDiscountedPrice.replace(
      /\B(?=(\d{3})+(?!\d))/g,
      ","
    );

    // Construct the new content by duplicating the original price replacing the numeric part with the discounted price
    const generatedDiscountedPriceText = originalPriceText.replace(
      /[\d,]+(\.\d+)?/,
      formattedWithCommas
    );
    // Return the generated discounted price text
    return generatedDiscountedPriceText;
  }
}
