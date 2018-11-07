# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionMonthsGiftCard do
  describe '#initialize' do
    it 'uses provided number of months and currency' do
      gift_card = SubscriptionMonthsGiftCard.new(3, 'SEK')

      expect(gift_card.number_of_months).to eq(3)
      expect(gift_card.currency).to eq('SEK')
    end
  end

  describe '#price' do
    it 'calculates price correctly for 3 months' do
      gift_card = SubscriptionMonthsGiftCard.new(3, 'sek')

      # 11 tons/year * 40 kr/ton / 12 months * 2 * 3 months
      expect(gift_card.price).to eq(220)
    end

    it 'calculates price correctly for 6 months' do
      gift_card = SubscriptionMonthsGiftCard.new(6, 'sek')

      # 11 tons/year * 40 kr/ton / 12 months * 2 * 6 months
      expect(gift_card.price).to eq(440)
    end

    context 'with USD' do
      it 'calculates price correctly for 3 months' do
        gift_card = SubscriptionMonthsGiftCard.new(3, 'usd')

        expect(gift_card.price).to eq(27)
      end

      it 'calculates price correctly for 6 months' do
        gift_card = SubscriptionMonthsGiftCard.new(6, 'usd')

        expect(gift_card.price).to eq(54)
      end
    end

    context 'with EUR' do
      it 'calculates price correctly for 3 months' do
        gift_card = SubscriptionMonthsGiftCard.new(3, 'eur')

        expect(gift_card.price).to eq(21)
      end

      it 'calculates price correctly for 6 months' do
        gift_card = SubscriptionMonthsGiftCard.new(6, 'eur')

        expect(gift_card.price).to eq(42)
      end
    end
  end
end
