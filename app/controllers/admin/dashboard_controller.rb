# frozen_string_literal: true

module Admin
  class DashboardController < AdminController
    def index
      @total_co2_bought = Project.all.sum('carbon_offset')
      @total_co2_consumed = Project.total_carbon_offset
      @total_sek_spent = Project.all.sum('cost_in_sek')
      @payouts_in_sek = (StripePayout.sum(:amount) / 100) + Invoice.sum(:amount_in_sek)
      @new_users = new_users
      @new_users_mean = new_users_mean(@new_users)
    end

    private

    def new_users
      User.order('date(created_at)').group('date(created_at)').count.transform_keys(&:to_s)
    end

    def new_users_mean(new_users)
      new_users_mean = {}
      new_users.each do |date, _|
        mean = 0
        (0..14).each do |i|
          mean += new_users[(date.to_date - i).to_s] if new_users[(date.to_date - i).to_s].present?
        end
        mean /= 14
        new_users_mean[date] = mean
      end
      new_users_mean
    end
  end
end
