/**
 * Unit tests for SM_GrantApplication.processApplication.
 *
 * Covers:
 *   - Validation failure (negative path) - exception propagated
 *   - New contact created (positive)
 *   - Existing contact updated (positive, lookup by phone)
 *   - Income >= 2000 (edge) - contact saved but no grants disbursed
 *   - Income <  2000 (positive) - grants are scheduled
 *   - Bulk-safety: a second application for a different citizen still
 *     produces an independent grant schedule
 */
@isTest
private class SM_GrantApplicationTest {

    private static GrantApplicationWrapper buildValidWrapper(String phone, Decimal income) {
        GrantApplicationWrapper w = new GrantApplicationWrapper();
        w.firstName = 'Jane';
        w.lastName = 'Doe';
        w.phone = phone;
        w.postalCode = '123456';
        w.monthlyIncome = income;
        w.supportOption = 'Option 1';
        return w;
    }

    @isTest
    static void processApplication_newContactWithLowIncome_createsContactAndGrants() {
        GrantApplicationWrapper w = buildValidWrapper('6500000010', 1500);

        Test.startTest();
        SM_GrantApplication.processApplication(w);
        Test.stopTest();

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, MailingPostalCode,
                   Monthly_Income__c, Support_Option__c
            FROM Contact
            WHERE Phone = '6500000010'
        ];
        System.assertEquals(1, contacts.size(), 'A single contact should have been created.');

        Contact c = contacts[0];
        System.assertEquals('Jane', c.FirstName);
        System.assertEquals('Doe', c.LastName);
        System.assertEquals('123456', c.MailingPostalCode);
        System.assertEquals(1500, c.Monthly_Income__c);
        System.assertEquals('Option 1', c.Support_Option__c);

        Integer grantCount = [
            SELECT COUNT()
            FROM Grant_Disbursed__c
            WHERE Contact__c = :c.Id
        ];
        System.assertEquals(
            3,
            grantCount,
            'Income below threshold should trigger Option 1 disbursement (3 months).'
        );
    }

    @isTest
    static void processApplication_newContactAtIncomeThreshold_savesContactWithoutGrants() {
        // Income == 2000 should NOT create grants ("< 2000" is the rule).
        GrantApplicationWrapper w = buildValidWrapper('6500000011', 2000);

        Test.startTest();
        SM_GrantApplication.processApplication(w);
        Test.stopTest();

        Contact c = [SELECT Id FROM Contact WHERE Phone = '6500000011'];
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :c.Id],
            'Citizens at or above the income threshold should not receive grants.'
        );
    }

    @isTest
    static void processApplication_newContactWithHighIncome_savesContactWithoutGrants() {
        GrantApplicationWrapper w = buildValidWrapper('6500000012', 5000);

        SM_GrantApplication.processApplication(w);

        Contact c = [SELECT Id FROM Contact WHERE Phone = '6500000012'];
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :c.Id]
        );
    }

    @isTest
    static void processApplication_existingContact_updatesInPlace() {
        insert new Contact(
            FirstName = 'Stale',
            LastName = 'Name',
            Phone = '6500000020',
            MailingPostalCode = '000000',
            Monthly_Income__c = 1800,
            Support_Option__c = 'Option 1'
        );
        Id originalId = [SELECT Id FROM Contact WHERE Phone = '6500000020'].Id;

        GrantApplicationWrapper w = buildValidWrapper('6500000020', 1200);
        w.firstName = 'Fresh';
        w.lastName = 'Name';
        w.postalCode = '999999';
        w.supportOption = 'Option 2';

        Test.startTest();
        SM_GrantApplication.processApplication(w);
        Test.stopTest();

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, MailingPostalCode,
                   Monthly_Income__c, Support_Option__c
            FROM Contact
            WHERE Phone = '6500000020'
        ];
        System.assertEquals(
            1,
            contacts.size(),
            'Existing contact should be updated, not duplicated.'
        );

        Contact updated = contacts[0];
        System.assertEquals(originalId, updated.Id, 'The same record should be reused.');
        System.assertEquals('Fresh', updated.FirstName);
        System.assertEquals('Name', updated.LastName);
        System.assertEquals('999999', updated.MailingPostalCode);
        System.assertEquals(1200, updated.Monthly_Income__c);
        System.assertEquals('Option 2', updated.Support_Option__c);

        // Option 2 = 6 months.
        System.assertEquals(
            6,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :originalId]
        );
    }

    @isTest
    static void processApplication_validationFailure_throwsAndPersistsNothing() {
        // Empty wrapper triggers every validation error.
        GrantApplicationWrapper w = new GrantApplicationWrapper();

        Boolean thrown = false;
        try {
            SM_GrantApplication.processApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assert(thrown, 'Validation failure must raise an AuraHandledException.');
        System.assertEquals(
            0,
            [SELECT COUNT() FROM Contact WHERE LastName != null],
            'No contact should be persisted when validation fails.'
        );
    }

    @isTest
    static void processApplication_invalidPhoneFormat_throws() {
        GrantApplicationWrapper w = buildValidWrapper('1234567890', 1000);

        Boolean thrown = false;
        try {
            SM_GrantApplication.processApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Phone not starting with 65 should fail validation.');
    }

    @isTest
    static void processApplication_invalidPostalCode_throws() {
        GrantApplicationWrapper w = buildValidWrapper('6500000030', 1000);
        w.postalCode = 'ABCDEF';

        Boolean thrown = false;
        try {
            SM_GrantApplication.processApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Non-numeric postal code should fail validation.');
    }

    @isTest
    static void processApplication_negativeIncome_throws() {
        GrantApplicationWrapper w = buildValidWrapper('6500000031', -10);

        Boolean thrown = false;
        try {
            SM_GrantApplication.processApplication(w);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Non-positive income should fail validation.');
    }

    @isTest
    static void processApplication_independentApplicationsCreateIndependentSchedules() {
        SM_GrantApplication.processApplication(buildValidWrapper('6500000040', 1000));
        SM_GrantApplication.processApplication(buildValidWrapper('6500000041', 1500));

        Map<Id, Contact> contactsByPhone = new Map<Id, Contact>(
            [SELECT Id, Phone FROM Contact WHERE Phone IN ('6500000040','6500000041')]
        );
        System.assertEquals(2, contactsByPhone.size(), 'Each phone should map to its own contact.');

        for (Contact c : contactsByPhone.values()) {
            System.assertEquals(
                3,
                [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :c.Id],
                'Each citizen should receive their own full schedule.'
            );
        }
    }
}
