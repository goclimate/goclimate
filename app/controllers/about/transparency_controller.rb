# frozen_string_literal: true

module About
  class TransparencyController < ApplicationController
    def show
      @unique_climate_neutral_users = User.with_active_subscription.count
      @total_carbon_offset = OffsettingStatistics.new.total_sold.tonnes.round
      @number_of_countries = User.distinct.pluck(:country).compact.count
      @number_of_businesses_helped = Invoice.distinct.pluck(:receiver).count +
                                     ClimateReport.distinct.pluck(:company_name).count
    end
  end
end
