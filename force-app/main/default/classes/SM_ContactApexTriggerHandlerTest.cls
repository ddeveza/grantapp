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

        Assert.areEqual('6512345678', c.Phone, 'Phone should be trimmed of surrounding whitespace.');
        Assert.areEqual('123456', c.MailingPostalCode, 'Postal code should be trimmed of surrounding whitespace.');
    }

    @isTest
    static void handle_leavesNullValuesUntouched() {
        Contact c = new Contact(
            FirstName = 'No',
            LastName = 'Values'
        );

        SM_ContactApexTriggerHandler.handle(new List<Contact>{ c });

        Assert.areEqual(null, c.Phone, 'Null phone should remain null (no NPE).');
        Assert.areEqual(null, c.MailingPostalCode, 'Null postal code should remain null (no NPE).');
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

        Assert.areEqual('6500000000', c.Phone);
        Assert.areEqual('654321', c.MailingPostalCode);
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

        Assert.areEqual('', c.Phone);
        Assert.areEqual('', c.MailingPostalCode);
    }
}
