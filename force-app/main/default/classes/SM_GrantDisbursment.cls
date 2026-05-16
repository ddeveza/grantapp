public with sharing class SM_GrantDisbursment {
    public static void processDisbursement(Id contactId, String supportOption) {
       
        Support_Option_Config__mdt optionConfig = DM_GrantDisbursement.getSupportOption(supportOption);
       
        if (optionConfig == null) {
            throw new AuraHandledException('Invalid support option configuration.');
        }
        
        Decimal totalGrantAmount = optionConfig.Amount__c * optionConfig.Duration_Amount__c;

        List<Grant_Disbursed__c> existingGrants = DM_GrantDisbursement.getGrantsForContact(contactId);

        //to get the already disbursed, grants to delete and latest disbursed date
        EM_GrantDisbursement.GrantDisbursementResult analysis = EM_GrantDisbursement.analyzeGrants(existingGrants);

        if (analysis.alreadyDisbursed >= totalGrantAmount) {
            throw new AuraHandledException('Citizen already received equal or greater support amount.');
        }

        if (!analysis.grantsToDelete.isEmpty()) delete analysis.grantsToDelete;
      
        Decimal remainingAmount = totalGrantAmount - analysis.alreadyDisbursed;

        Integer recordsNeeded = EM_GrantDisbursement.calculateRecordsNeeded(remainingAmount, optionConfig.Monthly_Amount__c);
        // Service Layer: Prepare new grants
        List<Grant_Disbursed__c> newGrants = new List<Grant_Disbursed__c>();
        Date startDate = analysis.latestDisbursedDate != null ? analysis.latestDisbursedDate.addMonths(1) : Date.today().toStartOfMonth();
        for (Integer i = 0; i < recordsNeeded; i++) {
            newGrants.add(new Grant_Disbursed__c(
                Contact__c = contactId,
                Disbursed_Amount__c = optionConfig.Monthly_Amount__c,
                Disbursed_Date__c = startDate.addMonths(i),
                Is_Disbursed__c = false
            ));
        }
        // Data Layer: Insert new grants
        if (!newGrants.isEmpty()) insert newGrants;
    }
}