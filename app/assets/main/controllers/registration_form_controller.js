import { Controller } from 'stimulus';
import submitForm from '../../util/submit_form';

export default class RegistrationFormController extends Controller {
  initialize() {
    this.loading = false;
    this.updateSubmitButton();
  }

  handleSubmit(event) {
    event.preventDefault();

    if (this.membership === 'free') {
      this.submitWithoutCardDetails();
    } else {
      this.submit();
    }
  }

  submit(event) {
    event.preventDefault();

    if (!this.formTarget.reportValidity()) { return; }

    if (!this.stripeCardElementController.complete) {
      this.setErrorMessage('Please complete your card details.');
      return;
    }

    this.enableLoadingState();
    this.setErrorMessage('');

    this.stripeCardElementController.populatePaymentMethodField()
      .then(() => submitForm(this.formTarget))
      .then((response) => response.json())
      .then((data) => this.resolveFormResponse(data))
      .catch((error) => {
        if (error.cardError) {
          this.setErrorMessage(error.message);
          return;
        }

        window.Sentry.captureException(error); // These errors are unexpected, so report them.
        this.setErrorMessage('An unexpected error occurred. Please start over and try again. If the issue remains, please contact us at hello@goclimate.com.');
      })
      .finally(() => {
        this.stripeCardElementController.invalidatePaymentMethodField();
        this.disableLoadingState();
      });
  }

  submitWithoutCardDetails() {
    if (!this.formTarget.reportValidity()) { return; }

    this.enableLoadingState();
    this.setErrorMessage('');

    submitForm(this.formTarget)
      .then((response) => response.json())
      .then((data) => this.resolveFormResponse(data))
      .catch((error) => {
        if (error.cardError) {
          this.setErrorMessage(error.message);
          return;
        }

        window.Sentry.captureException(error); // These errors are unexpected, so report them.
        this.setErrorMessage('An unexpected error occurred. Please start over and try again. If the issue remains, please contact us at hello@goclimate.com.');
      })
      .finally(() => {
        this.disableLoadingState();
      });
  }

  resolveFormResponse(data) {
    return new Promise((resolve) => {
      switch (data.next_step) {
        case 'redirect':
          window.location = data.success_url;
          resolve();
          break;
        case 'verification_required':
          window.stripe.confirmCardPayment(data.payment_intent_client_secret)
            .then((result) => {
              if (result.paymentIntent !== undefined) {
                window.location = data.success_url;
              } else {
                this.setErrorMessage(result.error.message);
              }
              resolve();
            });
          break;
        default:
          this.setErrorMessage(data.error.message);
          resolve();
      }
    });
  }

  setErrorMessage(errorMessage) {
    this.errorMessageTarget.innerText = errorMessage;
  }

  enableLoadingState() {
    this.loading = true;
    this.loadingIndicatorTarget.classList.remove('hidden');
    this.updateSubmitButton();
  }

  disableLoadingState() {
    this.loading = false;
    this.loadingIndicatorTarget.classList.add('hidden');
    this.updateSubmitButton();
  }

  updateSubmitButton() {
    if (!this.loading && this.privacyPolicyAgreementTarget.checked) {
      this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  get stripeCardElementController() {
    return this.application.getControllerForElementAndIdentifier(this.stripeCardElementTarget, 'stripe-card-element');
  }
}

RegistrationFormController.targets = ['form', 'privacyPolicyAgreement', 'submitButton', 'stripeCardElement', 'errorMessage', 'loadingIndicator'];
