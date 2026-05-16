/**
 * Unit tests for SM_ContactApexTriggerHandler.
 *
 * The handler is a pure in-memory transformation (trim phone and postal
 * code) so no DML is required. We exercise positive, negative and
 * edge-case (null / empty / bulk) paths.
 */
@isTest(IsParallel=true)
private class SM_ContactApexTriggerHandlerTest {

    @isTest
    static void handle_trimsPhoneAndPostalCode() {
        Contact c = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Phone = '   6512345678   ',
            MailingPostalCode = '  123456  '
        );

        Test.startTest();
        SM_ContactApexTriggerHandler.handle(new List<Contact>{ c });
        Test.stopTest();

        System.assertEquals(
            '6512345678',
            c.Phone,
            'Phone should be trimmed of surrounding whitespace.'
        );
        System.assertEquals(
            '123456',
            c.MailingPostalCode,
            'Postal code should be trimmed of surrounding whitespace.'
        );
    }

    @isTest
    static void handle_leavesNullValuesUntouched() {
        Contact c = new Contact(
            FirstName = 'No',
            LastName = 'Values'
        );

        SM_ContactApexTriggerHandler.handle(new List<Contact>{ c });

        System.assertEquals(
            null,
            c.Phone,
            'Null phone should remain null (no NPE).'
        );
        System.assertEquals(
            null,
            c.MailingPostalCode,
            'Null postal code should remain null (no NPE).'
        );
    }

    @isTest
    static void handle_doesNotMutateAlreadyCleanValues() {
        Contact c = new Contact(
            FirstName = 'Already',
            LastName = 'Clean',
            Phone = '6500000000',
            MailingPostalCode = '654321'
        );

        SM_ContactApexTriggerHandler.handle(new List<Contact>{ c });

        System.assertEquals('6500000000', c.Phone);
        System.assertEquals('654321', c.MailingPostalCode);
    }

    @isTest
    static void handle_whitespaceOnlyValuesAreTrimmedToEmpty() {
        // Edge case: when only whitespace is provided we expect an empty
        // string (not null) after trim - this guarantees downstream
        // validation can detect "blank" via String.isBlank().
        Contact c = new Contact(
            FirstName = 'Whitespace',
            LastName = 'Only',
            Phone = '     ',
            MailingPostalCode = '     '
        );

        SM_ContactApexTriggerHandler.handle(new List<Contact>{ c });

        System.assertEquals('', c.Phone);
        System.assertEquals('', c.MailingPostalCode);
    }

    @isTest
    static void handle_emptyListIsNoop() {
        SM_ContactApexTriggerHandler.handle(new List<Contact>());
        // Reaching this line without exception is the assertion.
        System.assert(true, 'Empty list should be handled silently.');
    }

    @isTest
    static void handle_bulkProcessingOf200Records() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'F' + i,
                LastName = 'L' + i,
                Phone = '  651234' + String.valueOf(1000 + i) + '  ',
                MailingPostalCode = '  12345' + String.valueOf(Math.mod(i, 10)) + '  '
            ));
        }

        Test.startTest();
        SM_ContactApexTriggerHandler.handle(contacts);
        Test.stopTest();

        for (Contact c : contacts) {
            System.assert(
                !c.Phone.startsWith(' ') && !c.Phone.endsWith(' '),
                'Phone should be trimmed for every record in the batch.'
            );
            System.assert(
                !c.MailingPostalCode.startsWith(' ')
                    && !c.MailingPostalCode.endsWith(' '),
                'Postal code should be trimmed for every record in the batch.'
            );
        }
    }
}
