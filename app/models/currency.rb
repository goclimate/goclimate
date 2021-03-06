# frozen_string_literal: true

Currency = Struct.new(:iso_code, :rounding_precision, :small_amount_price_step, :large_amount_price_step) do
  def self.from_iso_code(iso_code)
    return nil unless iso_code.present?

    "Currency::#{iso_code.upcase}".constantize
  rescue NameError
    nil
  end

  def to_s
    iso_code.to_s.upcase
  end

  def prefix
    prefix = I18n.translate("models.currency.prefix.#{iso_code}", default: 'DEFAULT', fallback: false)
    prefix unless prefix == 'DEFAULT'
  end

  def suffix
    suffix = I18n.translate("models.currency.suffix.#{iso_code}", default: 'DEFAULT', fallback: false)
    suffix unless suffix == 'DEFAULT'
  end

  def fractal_small_amount_price_step?
    small_amount_price_step % 100 != 0
  end
end

Currency::AUD = Currency.new(:aud, -1, 50, 1_00)
Currency::CAD = Currency.new(:cad, -1, 50, 1_00)
Currency::DKK = Currency.new(:dkk, -2, 5_00, 10_00)
Currency::EUR = Currency.new(:eur, -1, 50, 1_00)
Currency::GBP = Currency.new(:gbp, -1, 50, 1_00)
Currency::SEK = Currency.new(:sek, -2, 5_00, 10_00)
Currency::USD = Currency.new(:usd, -1, 50, 1_00)
