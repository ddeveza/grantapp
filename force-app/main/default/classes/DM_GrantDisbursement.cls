public with sharing class DM_GrantDisbursement {

    public static List<Grant_Disbursed__c> getGrantsForContact(Id contactId) {
        return [
            SELECT Id, Disbursed_Amount__c, Disbursed_Date__c, Is_Disbursed__c
            FROM Grant_Disbursed__c
            WHERE Contact__c = :contactId
        ];
    }

    public static Support_Option_Config__mdt getSupportOption(String supportOptionName) {
        
       List<Support_Option_Config__mdt> configs = [
            SELECT DeveloperName, Monthly_Amount__c Duration_Months__c
            FROM Support_Option_Config__mdt
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }

   
}