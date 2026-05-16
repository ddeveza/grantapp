public with sharing class SM_GrantApplicationController {

    @AuraEnabled
    public static void submitApplication(GrantApplicationWrapper request) {
        SM_GrantApplication.processApplication(request);
    }
}