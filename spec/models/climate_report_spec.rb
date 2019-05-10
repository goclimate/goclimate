# frozen_string_literal: true

require 'rails_helper'

def validate_presence_of(attribute)
  report = described_class.new

  report.validate

  expect(report.errors.keys).to include(attribute)
end

RSpec.describe ClimateReport do
  describe '#key' do
    it 'validates key to be unique' do
      existing = create(:climate_report, key: 'a9993e364706816aba3e25717850c26c9cd0d89d')
      report = described_class.new(key: existing.key)

      report.validate
      expect(report.errors).to have_key(:key)
    end

    it 'validates key to look like a SHA1 (40 hex characters)' do
      report = build(:climate_report)
      report.key = 'not a sha'

      report.validate
      expect(report.errors).to have_key(:key)
    end

    it 'generates key when creating new report' do
      report = create(:climate_report)

      expect(report.key).to be_present
    end

    it 'does not overwrite key when changing existing report' do
      report = create(:climate_report)

      expect do
        report.save
      end.not_to change(report, :key)
    end
  end

  describe '#company_name' do
    it 'validates presence' do
      validate_presence_of :company_name
    end
  end

  describe '#contact_email' do
    it 'validates presence' do
      validate_presence_of :contact_email
    end

    it 'validates email formatting' do
      report = described_class.new(contact_email: 'notanemail.com')

      report.validate

      expect(report.errors.keys).to include(:contact_email)
    end
  end

  describe '#employees' do
    it 'validates presence' do
      validate_presence_of :employees
    end
  end

  describe '#country' do
    it 'validates presence' do
      validate_presence_of :country
    end

    it 'validates as valid ISO3166 alpha 2 country code' do
      report = described_class.new(country: 'su')

      report.validate

      expect(report.errors.keys).to include(:country)
    end
  end

  describe '#calculation_period' do
    it 'validates presence' do
      validate_presence_of :calculation_period
    end
  end

  describe '#meals_vegetarian_share' do
    it 'validates as percentage share of 100%'
  end
end