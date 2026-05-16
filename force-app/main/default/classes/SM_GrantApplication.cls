public with sharing class SM_GrantApplication {

    /**
     * Main processing method
     */
    public static void processApplication(
        GrantApplicationWrapper request
    ) {

        // Validate first
        List<String> errors = UTI_GrantValidator.validate(request);

        if (!errors.isEmpty()) {

            throw new AuraHandledException(
                String.join(errors, '\n')
            );
        }

        // Find existing contact by phone
        Contact existingContact = DM_Contact.getContactByPhone(request.phone);

        Contact contactToSave;

        Boolean isExisting = existingContact != null;

        if (isExisting) {

            // Update existing
            existingContact.FirstName = request.firstName;
            existingContact.LastName = request.lastName;
            existingContact.MailingPostalCode =
                request.postalCode;
            existingContact.Monthly_Income__c =
                request.monthlyIncome;
            existingContact.Support_Option__c =
                request.supportOption;

            contactToSave = existingContact;

        } else {

            // Create new
            contactToSave = new Contact(
                FirstName = request.firstName,
                LastName = request.lastName,
                Phone = request.phone,
                MailingPostalCode = request.postalCode,
                Monthly_Income__c = request.monthlyIncome,
                Support_Option__c = request.supportOption
            );
        }

        upsert contactToSave;

        // Only create grants if income < 2000
        if (request.monthlyIncome < 2000) {

            SM_GrantDisbursment.processDisbursement(
                contactToSave.Id,
                request.supportOption
            );
        }
    }

 
}