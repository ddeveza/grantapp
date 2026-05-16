public with sharing class SM_ContactApexTriggerHandler {
    public static void handle( List<Contact> contacts) {

        for (Contact c : contacts) {
            // Normalize phone
            if (c.Phone != null) {
                c.Phone = c.Phone.trim();
            }

            // Normalize postal code
            if (c.MailingPostalCode != null) {
                c.MailingPostalCode =
                    c.MailingPostalCode.trim();
            }
        }
    }
}