public class GrantApplicationWrapper {
    @AuraEnabled public String firstName {get; set;}
    @AuraEnabled public String lastName {get; set;}
    @AuraEnabled public String phone {get; set;}
    @AuraEnabled public String postalCode {get; set;}
    @AuraEnabled public Decimal monthlyIncome {get; set;}
    @AuraEnabled public String supportOption {get; set;}
}