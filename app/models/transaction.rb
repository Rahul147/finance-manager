class Transaction < ApplicationRecord
  TRANSACTION_TYPE_LABELS = {
    expense: "Expense",
    investment: "Investment",
    transfer: "Transfer",
    loan: "Loan"
  }.freeze

  CATEGORY_LIST = {
    # Housing & utilities
    rent:                "Rent",
    home_loan_emi:       "Home Loan EMI",
    society_maintenance: "Society Maintenance",
    electricity:         "Electricity",
    water_gas:           "Water & Gas",
    broadband:           "Broadband",
    mobile_bill:         "Mobile Bill",
    tv_dth:              "TV / DTH",

    # Food & home
    groceries:           "Groceries",
    household_supplies:  "Household Supplies",
    dining_out:          "Dining Out",
    food_delivery:       "Food Delivery",

    # Transport
    local_transport:     "Local Transport",
    fuel:                "Fuel",
    vehicle_maintenance: "Vehicle Maintenance",
    parking_tolls:       "Parking & Tolls",

    # Travel
    travel_outstation:   "Outstation Travel",
    lodging:             "Hotels & Stay",

    # Health & insurance
    health_insurance:    "Health Insurance",
    life_insurance:      "Life Insurance",
    medical_fees:        "Doctor & Hospital",
    pharmacy:            "Pharmacy",
    fitness:             "Fitness",

    # Personal & family
    personal_care:       "Personal Care",
    clothing:            "Clothing & Footwear",
    education_fees:      "Education Fees",
    kids_expenses:       "Kids' Expenses",
    pet_care:            "Pet Care",

    # Subscriptions & fun
    digital_subscriptions: "Digital Subscriptions",
    entertainment:         "Entertainment",
    hobbies:               "Hobbies",

    # Home stuff
    home_appliances:     "Home Appliances",
    home_repairs:        "Home Repairs",

    # Social / cultural
    gifting:             "Gifting",
    festivals_pooja:     "Festivals & Pooja",
    donations:           "Donations",
    family_support:      "Family Support",

    # Money & work
    bank_charges:        "Bank Charges",
    card_fees:           "Card Fees",
    investments:         "Investments",
    loan_emi_other:      "Other Loan EMI",
    tax_payments:        "Tax Payments",
    professional_fees:   "Professional Fees",

    # Always last
    misc:                "Misc"
  }.freeze
  CATEGORY_KEY_SET = CATEGORY_LIST.keys.map(&:to_s).freeze
  CATEGORY_LABEL_TO_KEY = CATEGORY_LIST.each_with_object({}) do |(key, label), acc|
    acc[label] = key.to_s
  end.freeze

  belongs_to :user
  belongs_to :email

  enum :transaction_type, {
    expense: 0,
    investment: 1,
    transfer: 2,
    loan: 3
  }

  scope :expenses, -> { where(transaction_type: transaction_types[:expense]) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :ordered_newest, -> { order(transaction_date: :desc, created_at: :desc) }
  scope :search, lambda { |raw_query|
    query = raw_query.to_s.strip
    if query.blank?
      all
    else
      query_downcased = query.downcase
      sanitized = ApplicationRecord.sanitize_sql_like(query_downcased)
      pattern = "%#{sanitized}%"
      matching_category_keys = CATEGORY_LIST
        .select { |_key, label| label.downcase.include?(query_downcased) }
        .keys
        .map(&:to_s)

      sql = "LOWER(merchant) LIKE :pattern OR LOWER(category) LIKE :pattern OR LOWER(notes) LIKE :pattern"
      bindings = { pattern: pattern }

      if matching_category_keys.any?
        sql = "#{sql} OR category IN (:matching_category_keys)"
        bindings[:matching_category_keys] = matching_category_keys
      end

      where(sql, bindings)
    end
  }

  def self.category_options
    CATEGORY_LIST
  end

  def self.category_options_for_select
    CATEGORY_LIST.map { |key, label| [ label, key.to_s ] }
  end

  def self.category_key_for(value)
    return if value.blank?

    string_value = value.to_s
    return string_value if CATEGORY_KEY_SET.include?(string_value)

    CATEGORY_LABEL_TO_KEY[string_value]
  end

  def self.category_label_for(value)
    return if value.blank?

    key = category_key_for(value)
    return CATEGORY_LIST[key.to_sym] if key.present?

    value.to_s
  end

  def self.transaction_type_options_for_select
    TRANSACTION_TYPE_LABELS.map { |key, label| [ label, key.to_s ] }
  end

  validates :transaction_type, presence: true, inclusion: { in: transaction_types.keys }
  after_initialize :set_default_transaction_type, if: :new_record?

  def transaction_type_label
    key = transaction_type.presence || self.class.transaction_types.key(transaction_type_before_type_cast)
    return if key.blank?

    symbolized = key.to_s.to_sym
    TRANSACTION_TYPE_LABELS[symbolized] || symbolized.to_s.humanize
  end

  def category_display
    Transaction.category_label_for(category).presence || "Uncategorized"
  end

  def category_select_value
    Transaction.category_key_for(category)
  end

  def transaction_type_select_value
    key = transaction_type.presence || self.class.transaction_types.key(transaction_type_before_type_cast)
    key&.to_s
  end

  private

  def set_default_transaction_type
    self.transaction_type ||= :expense
  end
end
