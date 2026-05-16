import { LightningElement, track } from 'lwc';

import submitApplication
from '@salesforce/apex/SM_GrantApplicationController.submitApplication';

import Toast from 'lightning/toast';

export default class GrantApplicationForm
    extends LightningElement {

    @track firstName;
    @track lastName;
    @track phone;
    @track postalCode;
    @track monthlyIncome;
    @track supportOption;

    supportOptions = [
        { label: 'Option 1', value: 'Option 1' },
        { label: 'Option 2', value: 'Option 2' },
        { label: 'Option 3', value: 'Option 3' }
    ];

    handleFirstName(event) {
        this.firstName = event.target.value;
    }

    handleLastName(event) {
        this.lastName = event.target.value;
    }

    handlePhone(event) {
        this.phone = event.target.value;
    }

    handlePostalCode(event) {
        this.postalCode = event.target.value;
    }

    handleIncome(event) {
        this.monthlyIncome = event.target.value;
    }

    handleOption(event) {
        this.supportOption = event.target.value;
    }

    async submitForm() {
        const firstName = this.firstName;
        try {

            await submitApplication({
                request: {
                    firstName,
                    lastName: this.lastName,
                    phone: this.phone,
                    postalCode: this.postalCode,
                    monthlyIncome: this.monthlyIncome,
                    supportOption: this.supportOption
                }
            });

            this.showToast(
                'Success',
                'Application submitted successfully.',
                'success'
            );

        } catch (error) {

            this.showToast(
                'Error',
                error.body.message,
                'error'
            );
        }
    }

    showToast(title, message, variant) {
        Toast.show({
            label: title,
            message,
            variant
        }, this);
    }
}