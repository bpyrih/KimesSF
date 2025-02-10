public with sharing class ContactDAO {
    public List<Contact> getContactsByEmails(Set<String> emails) {
        return [
            SELECT Id, AccountId, Email
            FROM Contact 
            WHERE Email IN :emails
        ];
    }

    public Contact getContactByEmail(String email) {
        List<Contact> contacts = this.getContactsByEmails(new Set<String> { email });
        return contacts.isEmpty() ? null : contacts[0];
    }
}