# frozen_string_literal: true

class LifestyleFootprint < ApplicationRecord
  belongs_to :lifestyle_calculator
  belongs_to :user, optional: true

  attribute :country, :country
  attribute :housing, :greenhouse_gases
  attribute :food, :greenhouse_gases
  attribute :car, :greenhouse_gases
  attribute :flights, :greenhouse_gases
  attribute :consumption, :greenhouse_gases
  attribute :public, :greenhouse_gases
  attribute :total, :greenhouse_gases

  validates :key, uniqueness: true, format: { with: /\A[a-f0-9]{40}\z/ }
  validates_presence_of :country, :housing, :food, :car, :flights, :consumption, :public, :total
  validates :car_distance_answer, :flight_hours_answer, numericality: { greater_than_or_equal_to: 0 }
  validate :answers_exist_in_calculator

  before_validation :generate_key

  def update_from_lifestyle_calculator
    self.attributes = lifestyle_calculator.calculate(
      [
        :region, :home, :home_area, :heating, :green_electricity, :food, :shopping, :car_type, :car_distance,
        :flight_hours
      ].map { |q| [q, send("#{q}_answer")] }.to_h
    )
  end

  def to_param
    key
  end

  private

  def answers_exist_in_calculator
    [
      :region, :home, :home_area, :heating, :green_electricity, :food, :shopping, :car_type
    ].each do |category|
      field = "#{category}_answer".to_sym
      available_options = lifestyle_calculator&.option_keys_for_category(category)

      next if available_options.nil?

      available_options.include?(send(field)) ||
        errors.add(field, "must be one of #{available_options.join(', ')}")
    end
  end

  def generate_key
    self.key = SecureRandom.hex(20) unless key.present?
  end
end
