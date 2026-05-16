/**
 * Unit tests for SM_GrantDisbursment.
 *
 * Relies on the seeded Support_Option_Config__mdt custom metadata records
 * (Option 1 / Option 2 / Option 3) shipped with the project. Custom
 * metadata is automatically visible to Apex tests so no extra seeding is
 * required.
 *
 * Option 1 -> 3 months * $500  = $1,500 total
 * Option 2 -> 6 months * $300  = $1,800 total
 * Option 3 -> 12 months * $140 = $1,680 total
 */
@isTest
private class SM_GrantDisbursmentTest {

    private static final String OPTION_1 = 'Option 1';
    private static final Decimal OPTION_1_MONTHLY = 500;
    private static final Integer OPTION_1_DURATION = 3;

    @TestSetup
    static void seedContact() {
        insert new Contact(
            FirstName = 'Disbursement',
            LastName = 'Tester',
            Phone = '6500000099',
            MailingPostalCode = '111111',
            Monthly_Income__c = 1000,
            Support_Option__c = OPTION_1
        );
    }

    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    @isTest
    static void processDisbursement_noExistingGrants_createsAllGrants() {
        Id contactId = getContactId();

        Test.startTest();
        SM_GrantDisbursment.processDisbursement(contactId, OPTION_1);
        Test.stopTest();

        List<Grant_Disbursed__c> grants = [
            SELECT Id, Disbursed_Amount__c, Disbursed_Date__c, Is_Disbursed__c
            FROM Grant_Disbursed__c
            WHERE Contact__c = :contactId
            ORDER BY Disbursed_Date__c
        ];

        System.assertEquals(
            OPTION_1_DURATION,
            grants.size(),
            'Should create one grant per month of the support option.'
        );

        Date expectedStart = Date.today().toStartOfMonth();
        for (Integer i = 0; i < grants.size(); i++) {
            System.assertEquals(
                OPTION_1_MONTHLY,
                grants[i].Disbursed_Amount__c,
                'Each grant should match the configured monthly amount.'
            );
            System.assertEquals(
                expectedStart.addMonths(i),
                grants[i].Disbursed_Date__c,
                'Grants should be scheduled one month apart starting this month.'
            );
            System.assertEquals(
                false,
                grants[i].Is_Disbursed__c,
                'Newly created grants should default to not yet disbursed.'
            );
        }
    }

    @isTest
    static void processDisbursement_invalidSupportOption_throws() {
        Id contactId = getContactId();
        Boolean thrown = false;

        try {
            SM_GrantDisbursment.processDisbursement(contactId, 'Not A Real Option');
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assert(
            thrown,
            'Invalid support option should raise an AuraHandledException.'
        );

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :contactId],
            'No grants should be created when the option is invalid.'
        );
    }

    @isTest
    static void processDisbursement_partiallyDisbursed_createsOnlyRemaining() {
        Id contactId = getContactId();

        // Simulate that the citizen has already received 2 of 3 months.
        insert new List<Grant_Disbursed__c>{
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(-2),
                Is_Disbursed__c = true
            ),
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(-1),
                Is_Disbursed__c = true
            )
        };

        Test.startTest();
        SM_GrantDisbursment.processDisbursement(contactId, OPTION_1);
        Test.stopTest();

        List<Grant_Disbursed__c> grants = [
            SELECT Id, Is_Disbursed__c, Disbursed_Date__c
            FROM Grant_Disbursed__c
            WHERE Contact__c = :contactId
            ORDER BY Disbursed_Date__c
        ];

        System.assertEquals(
            OPTION_1_DURATION,
            grants.size(),
            'Total grants (existing + newly created) should equal the option duration.'
        );

        Integer disbursedCount = 0;
        Integer pendingCount = 0;
        for (Grant_Disbursed__c g : grants) {
            if (g.Is_Disbursed__c) {
                disbursedCount++;
            } else {
                pendingCount++;
            }
        }
        System.assertEquals(2, disbursedCount, 'Existing disbursed grants should be preserved.');
        System.assertEquals(1, pendingCount, 'Only the remaining months should be created.');
    }

    @isTest
    static void processDisbursement_alreadyFullyDisbursed_throws() {
        Id contactId = getContactId();

        // 3 grants of $500 == $1,500 == full Option 1 entitlement.
        insert new List<Grant_Disbursed__c>{
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(-3),
                Is_Disbursed__c = true
            ),
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(-2),
                Is_Disbursed__c = true
            ),
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(-1),
                Is_Disbursed__c = true
            )
        };

        Boolean thrown = false;
        try {
            Test.startTest();
            SM_GrantDisbursment.processDisbursement(contactId, OPTION_1);
            Test.stopTest();
        } catch (AuraHandledException e) {
            thrown = true;
        }

        System.assert(
            thrown,
            'Should refuse to issue further grants when the citizen is already fully supported.'
        );

        System.assertEquals(
            3,
            [SELECT COUNT() FROM Grant_Disbursed__c WHERE Contact__c = :contactId],
            'No grants should be inserted on top of a fully disbursed plan.'
        );
    }

    @isTest
    static void processDisbursement_overDisbursed_alsoThrows() {
        Id contactId = getContactId();

        // Total $2,000 already disbursed — greater than the $1,500 cap.
        insert new List<Grant_Disbursed__c>{
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = 1000,
                Disbursed_Date__c = Date.today().addMonths(-2),
                Is_Disbursed__c = true
            ),
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = 1000,
                Disbursed_Date__c = Date.today().addMonths(-1),
                Is_Disbursed__c = true
            )
        };

        Boolean thrown = false;
        try {
            SM_GrantDisbursment.processDisbursement(contactId, OPTION_1);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        System.assert(thrown, 'Over-disbursed citizens should also be blocked.');
    }

    @isTest
    static void processDisbursement_deletesUndisbursedAndReinserts() {
        Id contactId = getContactId();

        // Two pending (not-yet-disbursed) grants — these should be wiped and
        // replaced by a fresh schedule starting from the current month.
        insert new List<Grant_Disbursed__c>{
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(2),
                Is_Disbursed__c = false
            ),
            new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = OPTION_1_MONTHLY,
                Disbursed_Date__c = Date.today().addMonths(3),
                Is_Disbursed__c = false
            )
        };

        Test.startTest();
        SM_GrantDisbursment.processDisbursement(contactId, OPTION_1);
        Test.stopTest();

        List<Grant_Disbursed__c> grants = [
            SELECT Id, Disbursed_Date__c, Is_Disbursed__c
            FROM Grant_Disbursed__c
            WHERE Contact__c = :contactId
            ORDER BY Disbursed_Date__c
        ];

        System.assertEquals(
            OPTION_1_DURATION,
            grants.size(),
            'Pending grants should be replaced by a complete fresh schedule.'
        );

        Date expectedStart = Date.today().toStartOfMonth();
        for (Integer i = 0; i < grants.size(); i++) {
            System.assertEquals(
                expectedStart.addMonths(i),
                grants[i].Disbursed_Date__c,
                'Fresh schedule should restart from the current month.'
            );
            System.assertEquals(false, grants[i].Is_Disbursed__c);
        }
    }

    @isTest
    static void processDisbursement_supportsOtherOptions() {
        Id contactId = getContactId();

        Test.startTest();
        SM_GrantDisbursment.processDisbursement(contactId, 'Option 2');
        Test.stopTest();

        List<Grant_Disbursed__c> grants = [
            SELECT Id, Disbursed_Amount__c
            FROM Grant_Disbursed__c
            WHERE Contact__c = :contactId
        ];
        System.assertEquals(6, grants.size(), 'Option 2 should yield 6 monthly grants.');
        for (Grant_Disbursed__c g : grants) {
            System.assertEquals(300, g.Disbursed_Amount__c);
        }
    }
}
