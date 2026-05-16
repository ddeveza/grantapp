public with sharing class EM_GrantDisbursement {
    public class GrantDisbursementResult {
        public Integer alreadyDisbursedCount = 0;
        public Decimal totalDisbursed = 0;
        public Date latestDisbursedDate;
        public List<Grant_Disbursed__c> grantsToDelete = new List<Grant_Disbursed__c>();
    }

    public static GrantDisbursementResult analyzeGrants(List<Grant_Disbursed__c> existingGrants) {
        GrantDisbursementResult result = new GrantDisbursementResult();
        for (Grant_Disbursed__c grant : existingGrants) {
            if (grant.Is_Disbursed__c) {
                result.alreadyDisbursedCount++;
                result.totalDisbursed += grant.Disbursed_Amount__c;
                if (result.latestDisbursedDate == null || grant.Disbursed_Date__c > result.latestDisbursedDate) {
                    result.latestDisbursedDate = grant.Disbursed_Date__c;
                }
            } else {
                result.grantsToDelete.add(grant);
            }
        }
        return result;
    }

}