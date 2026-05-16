public with sharing class DM_Contact {
     public static Contact getContactByPhone( String phone ) {
        List<Contact> contacts = [
            SELECT Id,
                   FirstName,
                   LastName,
                   Phone,
                   MailingPostalCode,
                   Monthly_Income__c,
                   Support_Option__c
            FROM Contact
            WHERE Phone = :phone
            LIMIT 1
        ];

        return contacts.isEmpty() ? null : contacts[0];
    }
}