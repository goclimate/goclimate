# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionManager do
  subject(:manager) { described_class.for_new_customer(email) }

  let(:email) { 'test@example.com' }
  let(:plan) { Stripe::Plan.construct_from(stripe_json_fixture('plan.json')) }
  let(:payment_method_id) { 'pm_some_card' }

  let(:created_subscription) do
    Stripe::Subscription.construct_from(stripe_json_fixture('subscription.json'))
  end

  before do
    allow(Stripe::Customer).to receive(:create).and_return(
      Stripe::Customer.construct_from(stripe_json_fixture('customer.json'))
    )
    allow(Stripe::Customer).to receive(:update)
    allow(Stripe::PaymentMethod).to receive(:attach)
    allow(Stripe::PaymentMethod).to receive(:detach)
    allow(Stripe::Subscription).to receive(:create).and_return(created_subscription)
    allow(Stripe::Subscription).to receive(:update).and_return(created_subscription)
  end

  describe '.for_new_customer' do
    it 'creates a new customer' do
      described_class.for_new_customer(email)

      expect(Stripe::Customer).to have_received(:create)
    end

    it 'sets email for new customer' do
      described_class.for_new_customer(email)

      expect(Stripe::Customer).to have_received(:create).with hash_including(email: email)
    end
  end

  describe '.price_for_footprint' do
    it 'calculates monthly price using doubling buffer' do
      price = described_class.price_for_footprint(GreenhouseGases.new(12_000), Currency::SEK)

      expect(price).to eq(Money.new(80_00, :sek))
    end

    it 'ceils SEK prices to nearest 5 SEK' do
      price = described_class.price_for_footprint(GreenhouseGases.new(11_400), Currency::SEK)

      expect(price).to eq(Money.new(80_00, :sek))
    end

    it 'rounds USD prices to nearest 10 cents' do
      price = described_class.price_for_footprint(GreenhouseGases.new(12_900), Currency::USD)

      expect(price).to eq(Money.new(10_10, :usd))
    end

    it 'rounds EUR prices to nearest 10 cents' do
      price = described_class.price_for_footprint(GreenhouseGases.new(15_165), Currency::EUR)

      expect(price).to eq(Money.new(10_10, :eur))
    end
  end

  describe '#sign_up' do
    it 'returns true indicating success' do
      expect(manager.sign_up(plan, payment_method_id)).to be(true)
    end

    it 'sets payment_method as customer default_payment_method' do
      manager.sign_up(plan, payment_method_id)

      expect(Stripe::Customer).to have_received(:update)
        .with(manager.customer.id, hash_including(invoice_settings: { default_payment_method: payment_method_id }))
    end

    it 'attaches payment_method to customer' do
      manager.sign_up(plan, payment_method_id)

      expect(Stripe::PaymentMethod).to have_received(:attach)
        .with(payment_method_id, hash_including(customer: manager.customer.id))
    end

    it 'creates new subscription' do
      manager.sign_up(plan, payment_method_id)

      expect(Stripe::Subscription).to have_received(:create)
    end

    it 'uses customer for new subscription' do
      manager.sign_up(plan, payment_method_id)

      expect(Stripe::Subscription).to have_received(:create).with hash_including(customer: manager.customer.id)
    end

    it 'uses provided plan for new subscription' do
      manager.sign_up(plan, payment_method_id)

      expect(Stripe::Subscription).to have_received(:create).with hash_including(plan: plan.id)
    end

    it 'sets intent_to_confirm to nil' do
      manager.sign_up(plan, payment_method_id)

      expect(manager.intent_to_confirm).to be_nil
    end

    context 'when new subscription is incomplete and requires_action' do
      let(:created_subscription) do
        Stripe::Subscription.construct_from(stripe_json_fixture('subscription_requires_action.json'))
      end

      it 'sets intent_to_confirm to PaymentIntent that needs confirmation' do
        manager.sign_up(plan, payment_method_id)

        expect(manager.intent_to_confirm).to be_a(Stripe::PaymentIntent)
      end
    end
  end

  describe '#confirmation_required?' do
    it 'does not require confirmation by default' do
      expect(manager.confirmation_required?).to be false
    end

    context 'when intent_to_confirm has been set' do
      let(:created_subscription) do
        Stripe::Subscription.construct_from(stripe_json_fixture('subscription_requires_action.json'))
      end

      before do
        manager.sign_up(plan, payment_method_id)
      end

      it 'requires confirmation' do
        expect(manager.confirmation_required?).to be true
      end
    end
  end

  context 'when customer already exists' do
    subject(:manager) { described_class.new(customer) }

    let(:customer) do
      Stripe::Customer.construct_from(stripe_json_fixture('customer.json'))
    end

    describe '#new' do
      it 'returns an instance' do
        expect(described_class.new(customer)).to be_an_instance_of(described_class)
      end

      it 'sets provided customer' do
        manager = described_class.new(customer)

        expect(manager.customer).to be(customer)
      end
    end

    describe '#cancel' do
      before do
        allow(manager.subscription).to receive(:delete)
      end

      it 'cancels current subscription' do
        manager.cancel

        expect(manager.subscription).to have_received(:delete)
      end

      it 'removes the current payment methods' do
        manager.cancel

        expect(Stripe::PaymentMethod).to have_received(:detach)
          .with(manager.customer.invoice_settings&.default_payment_method)
      end
    end

    describe '#update' do
      let(:new_payment_method_id) { 'new_payment_method_id' }
      let(:new_plan) { Stripe::Plan.construct_from(stripe_json_fixture('plan_alternative.json')) }

      before do
        allow(Stripe::SetupIntent).to receive(:create).and_return(
          Stripe::SetupIntent.construct_from(stripe_json_fixture('setup_intent_succeeded.json'))
        )
      end

      it 'returns true to indicate success' do
        expect(manager.update(new_plan)).to be(true)
      end

      context 'when new plan is same as current' do
        it 'does not update subscription' do
          manager.update(manager.subscription.plan)

          expect(Stripe::Subscription).not_to have_received(:update)
        end

        it 'does not create new subscription' do
          manager.update(manager.subscription.plan)

          expect(Stripe::Subscription).not_to have_received(:create)
        end
      end

      context 'when new plan is different than current' do
        it 'updates subscription with new plan and prorate false' do
          subscription_id = manager.subscription.id

          manager.update(new_plan)

          expect(Stripe::Subscription).to have_received(:update)
            .with(subscription_id, hash_including(prorate: false, plan: new_plan.id))
        end
      end

      context 'when customer has no existing subscription' do
        let(:customer) do
          Stripe::Customer.construct_from(stripe_json_fixture('customer_without_subscription.json'))
        end

        it 'raises SubscriptionMissingError' do
          expect do
            manager.update(new_plan)
          end.to raise_error(SubscriptionManager::SubscriptionMissingError)
        end
      end

      context 'with payment_method_id provided' do
        it 'attaches payment method to customer' do
          manager.update(new_plan, new_payment_method_id)

          expect(Stripe::PaymentMethod).to have_received(:attach)
            .with(new_payment_method_id, hash_including(customer: customer.id))
        end

        it 'sets new payment method as customer default' do
          manager.update(new_plan, new_payment_method_id)

          expect(Stripe::Customer).to have_received(:update)
            .with(customer.id,
                  hash_including(invoice_settings: { default_payment_method: new_payment_method_id }))
        end

        it 'updates card before updating subscription' do
          allow(Stripe::Customer).to receive(:update) do
            expect(Stripe::Subscription).not_to have_received(:update)
          end

          manager.update(new_plan, new_payment_method_id)
        end

        it 'sets intent_to_confirm to nil' do
          manager.update(new_plan, new_payment_method_id)

          expect(manager.intent_to_confirm).to be_nil
        end

        it 'creates a SetupIntent for new payment method' do
          manager.update(new_plan, new_payment_method_id)

          expect(Stripe::SetupIntent)
            .to have_received(:create).with(hash_including(payment_method: new_payment_method_id))
        end

        it 'attempts to confirm a SetupIntent for new payment method immediately' do
          manager.update(new_plan, new_payment_method_id)

          expect(Stripe::SetupIntent).to have_received(:create).with(hash_including(confirm: true))
        end

        it 'sets customer for SetupIntent' do
          manager.update(new_plan, new_payment_method_id)

          expect(Stripe::SetupIntent).to have_received(:create).with(hash_including(customer: customer.id))
        end
      end

      context 'with payment_method_id that triggers 3D Secure' do
        before do
          allow(Stripe::SetupIntent).to receive(:create).and_return(
            Stripe::SetupIntent.construct_from(stripe_json_fixture('setup_intent_requires_action.json'))
          )
        end

        it 'sets intent_to_confirm to SetupIntent that needs confirmation' do
          manager.update(new_plan, new_payment_method_id)

          expect(manager.intent_to_confirm).to be_a(Stripe::SetupIntent)
        end
      end
    end
  end
end
