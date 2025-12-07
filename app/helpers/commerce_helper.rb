module CommerceHelper
  def display_price(price, options = {})
    # Used for displaying the price with currency symbol and recurring interval (if applicable)

    # Define the currency symbol
    symbol = options[:symbol] || "$"

    # Override text shown after the price (defaults to the recurring interval, if applicable)
    append_content = options[:append_content] ||
                     (price.recurring? ? "/#{price.recurring_interval}" : nil)

    # Don't show the recurring interval
    no_append_content = options[:no_append_content] || false

    # Use precision 2 unless cents are 0.
    amount = price.amount
    formatted_amount = if amount % 100 == 0
      display_amount(amount, hide_zero_cents: true)
    else
      display_amount(amount, hide_zero_cents: false)
    end

    # Handle hiding of symbol and/or appended content, if needed
    append_content_output = no_append_content ? "" : "#{append_content}"

    # Define the position of the symbol (before or after)
    symbol_position = options[:symbol_position] || "before"

    # Assemble the final output and return the result either as a hash (for easy styling) or as a string
    output_hash = options[:output_hash] || false

    if output_hash # we will assemble and return a hash
      hash = {
        amount: formatted_amount,
        append_content: append_content_output,
        symbol: symbol,
        symbol_position: symbol_position
      }
      hash
    else # we will assemble and return a string

      string = if symbol_position == "before"
        "#{symbol}#{formatted_amount}#{append_content_output}"
      else
        "#{formatted_amount}#{symbol}#{append_content_output}"
      end
      string
    end
  end

  def display_amount(amount, options = {})
    # Used to display a clean price amount with or without cents

    hide_zero_cents = options[:hide_zero_cents] || false

    if hide_zero_cents && amount % 100 == 0
      number_with_delimiter(amount / 100)
    else
      number_with_delimiter(number_with_precision(amount / 100.0, precision: 2))
    end
  end

  def display_recurring_interval(recurring_interval)
    case recurring_interval
    when "day"
      t("commerce.helpers.recurring_interval.day", default: "Daily")
    when "week"
      t("commerce.helpers.recurring_interval.week", default: "Weekly")
    when "month"
      t("commerce.helpers.recurring_interval.month", default: "Monthly")
    when "quarter"
      t("commerce.helpers.recurring_interval.quarter", default: "Quarterly")
    when "year"
      t("commerce.helpers.recurring_interval.year", default: "Yearly")
    end
  end

  def show_plan_toggle?
    Commerce::Plan.active.where.not(price_a_id: nil).where.not(price_b_id: nil).any?
  end

  def default_plan_identifier
    if show_plan_toggle?
      "b" # b is typically the yearly plan, shown by default
    else # the toggle isn't shown, so show whichever plan price is present
      Commerce::Plan.active.exists?(price_a_id: nil) ? "b" : "a"
    end
  end

  def currency_symbol(currency)
    currency = currency.upcase
    case currency
    when "USD"
      t("commerce.helpers.currency.usd", default: "$")
    when "EUR"
      t("commerce.helpers.currency.eur", default: "€")
    end
  end
end
