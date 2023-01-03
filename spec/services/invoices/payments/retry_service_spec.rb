# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invoices::Payments::RetryService, type: :service do
  subject(:retry_service) { described_class.new(invoice: invoice) }

  let(:invoice) { create(:invoice, customer: customer, status: 'finalized') }
  let(:customer) { create(:customer, payment_provider: payment_provider) }
  let(:payment_provider) { 'stripe' }

  describe '#call' do
    it 'enqueues a job to create a new stripe payment' do
      expect do
        retry_service.call
      end.to have_enqueued_job(Invoices::Payments::StripeCreateJob)
    end

    it 'enqueues a SendWebhookJob' do
      expect do
        retry_service.call
      end.to have_enqueued_job(SendWebhookJob).with(:invoice, Invoice)
    end

    context 'with gocardless payment provider' do
      let(:payment_provider) { 'gocardless' }

      it 'enqueues a job to create a gocardless payment' do
        expect do
          retry_service.call
        end.to have_enqueued_job(Invoices::Payments::GocardlessCreateJob)
      end
    end

    context 'when invoice does not exist' do
      let(:invoice) { nil }

      it 'returns an error' do
        result = retry_service.call

        expect(result).not_to be_success
        expect(result.error.error_code).to eq('invoice_not_found')
      end
    end

    context 'when invoice payment status is already succeeded' do
      let(:invoice) { create(:invoice, customer: customer, status: 'finalized', payment_status: 'succeeded') }

      it 'returns an error' do
        result = retry_service.call

        expect(result).not_to be_success
        expect(result.error).to be_a(BaseService::MethodNotAllowedFailure)
        expect(result.error.code).to eq('invalid_status')
      end
    end

    context 'when invoice status is draft' do
      let(:invoice) { create(:invoice, customer: customer, payment_status: 'pending', status: 'draft') }

      it 'returns an error' do
        result = retry_service.call

        expect(result).not_to be_success
        expect(result.error).to be_a(BaseService::MethodNotAllowedFailure)
        expect(result.error.code).to eq('invalid_status')
      end
    end

    context 'when invoice is not ready for payment processing' do
      let(:invoice) do
        create(
          :invoice,
          customer: customer,
          status: 'finalized',
          payment_status: 'failed',
          ready_for_payment_processing: false,
        )
      end

      it 'returns an error' do
        result = retry_service.call

        expect(result).not_to be_success
        expect(result.error).to be_a(BaseService::MethodNotAllowedFailure)
        expect(result.error.code).to eq('payment_processor_is_currently_handling_payment')
      end
    end
  end
end
