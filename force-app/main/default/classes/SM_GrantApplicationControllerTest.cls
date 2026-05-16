/**
 * Unit tests for SM_GrantApplicationController.
 *
 * The controller is a thin @AuraEnabled facade that delegates to
 * SM_GrantApplication.processApplication. We verify the happy-path
 * delegation as well as the exception propagation contract that LWC
 * components rely on.
 */
@isTest
private class SM_GrantApplicationControllerTest {

    private static GrantApplicationWrapper buildValidWrapper(String phone) {
        GrantApplicationWrapper w = new GrantApplicationWrapper();
        w.firstName = 'Aura';
        w.lastName = 'Caller';
        w.phone = phone;
        w.postalCode = '654321';
        w.monthlyIncome = 1500;
        w.supportOption = 'Option 2';
        return w;
    }

    @isTest
    static void submitApplication_delegatesToServiceAndPersistsContact() {
        GrantApplicationWrapper w = buildValidWrapper('6577777777');

        Test.startTest();
        SM_GrantApplicationController.submitApplication(w);
        Test.stopTest();

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, MailingPostalCode,
                   Monthly_Income__c, Support_Option__c
            FROM Contact
            WHERE Phone = '6577777777'
        ];
        System.assertEquals(1, contacts.size(), 'Controller should persist the contact via the service.');
        System.assertEquals('Aura', contacts[0].FirstName);
        System.assertEquals('Option 2', contacts[0].Support_Option__c);

        // Option 2 = 6 grants of $300.
        System.assertEquals(
            6,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :contacts[0].Id],
            'Controller should also trigger downstream disbursement scheduling.'
        );
    }

    @isTest
    static void submitApplication_propagatesValidationExceptions() {
        // Missing every required field should bubble up from the validator.
        GrantApplicationWrapper w = new GrantApplicationWrapper();

        Boolean thrown = false;
        try {
            SM_GrantApplicationController.submitApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assert(
            thrown,
            'Validation errors from the service must surface to the @AuraEnabled caller.'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Contact WHERE LastName != null],
            'No contact should be created when the controller call fails validation.'
        );
    }

    @isTest
    static void submitApplication_propagatesInvalidSupportOptionFromService() {
        GrantApplicationWrapper w = buildValidWrapper('6588888888');
        w.supportOption = 'Bogus Option';

        Boolean thrown = false;
        try {
            SM_GrantApplicationController.submitApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assert(
            thrown,
            'An unknown support option must propagate as an AuraHandledException to the LWC.'
        );
    }
}
