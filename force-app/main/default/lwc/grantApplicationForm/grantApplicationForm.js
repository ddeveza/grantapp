import { LightningElement, track } from 'lwc';

import submitApplication
    from '@salesforce/apex/GrantApplicationController.submitApplication';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

export default class GrantApplicationForm
    extends LightningElement {

    @track firstName;
    @track lastName;
    @track phone;
    @track postalCode;
    @track monthlyIncome;
    @track supportOption;

    supportOptions = [
        { label: 'Option 1', value: 'Option_1' },
        { label: 'Option 2', value: 'Option_2' },
        { label: 'Option 3', value: 'Option_3' }
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

        try {

            await submitApplication({

                request: {
                    firstName: this.firstName,
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

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}