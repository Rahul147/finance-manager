# app/services/transaction_extractor.rb
require "openai"
require "json"

module TransactionExtractor
  module_function

  def extract!(email)
    content = email.snippet.to_s
    if content.blank?
      Rails.logger.info("TransactionExtractor: SKIP email_id=#{email.id} reason=blank_content")
      return
    end

    OpenAI.configure do |config|
      config.access_token = Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"]
      config.log_errors = true
    end

    client = OpenAI::Client.new(
      log_errors: true
    )

    prompt = <<~TXT
      Extract a purchase transaction from the email and respond ONLY with minified JSON:
      {
        "bankName": string,
        "amount": number,
        "currency": string (ISO 4217),
        "type": "DEBIT_CARD" | "CREDIT_CARD" | "UPI" | "OTHER",
        "spendType": string,
        "beneficiaryName": string|null,
        "paymentInstrumentNumber": string|null,
        "transactionDate": "YYYY-MM-DD",
        "notes": string
      }
      If not a transaction, return {"amount":0}.
      Email content:
    TXT

    Rails.logger.info("TransactionExtractor: START email_id=#{email.id} content_len=#{content.length}")
    response = client.chat(
      parameters: {
        messages: [
          { role: "system", content: "Extract structured data and return ONLY minified JSON." },
          { role: "user", content: prompt + content }
        ],
        model: :"gpt-4o-mini",
        temperature: 0
      }
    )

    json_str = response.dig("choices", 0, "message", "content")
    unless json_str
      Rails.logger.warn("TransactionExtractor: SKIP email_id=#{email.id} reason=no_openai_response")
      return
    end

    data = JSON.parse(json_str) rescue nil
    unless data
      Rails.logger.warn("TransactionExtractor: SKIP email_id=#{email.id} reason=json_parse_failed snippet=#{json_str.to_s[0, 120]}")
      return
    end

    if data["amount"].to_f <= 0
      Rails.logger.info("TransactionExtractor: SKIP email_id=#{email.id} reason=no_transaction amount=#{data["amount"]}")
      return
    end

    amount_cents = (data["amount"].to_f * 100).round
    attrs = {
      email: email,
      user_id: email.user_id,
      merchant: data["beneficiaryName"].presence || data["bankName"].presence || "Unknown",
      amount_cents: amount_cents,
      currency: data["currency"].to_s.upcase.presence || "INR",
      transaction_date: data["transactionDate"].presence,
      category: data["spendType"].to_s,
      notes: data["notes"].to_s,
      status: "parsed",
      metadata: {
        bankName: data["bankName"],
        type: data["type"],
        paymentInstrumentNumber: data["paymentInstrumentNumber"]
      }.to_json
    }

    if email.financial_transaction
      email.financial_transaction.update!(attrs)
      Rails.logger.info("TransactionExtractor: SUCCESS email_id=#{email.id} action=updated amount_cents=#{amount_cents} merchant=#{attrs[:merchant]}")
    else
      email.create_financial_transaction!(attrs)
      Rails.logger.info("TransactionExtractor: SUCCESS email_id=#{email.id} action=created amount_cents=#{amount_cents} merchant=#{attrs[:merchant]}")
    end
  end
end
