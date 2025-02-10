@isTest
private class ContactDAOTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        List<Contact> testContacts = new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', AccountId = testAccount.Id),
            new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com', AccountId = testAccount.Id)
        };
        insert testContacts;
    }

    @isTest
    static void testGetContactsByEmails() {
        Set<String> emails = new Set<String>{ 'john.doe@example.com', 'jane.smith@example.com' };

        ContactDAO contactDAO = new ContactDAO();
        List<Contact> results = contactDAO.getContactsByEmails(emails);

        Assert.areEqual(2, results.size(), 'There should be two contacts returned.');
        for (Contact contact : results) {
            Assert.isNotNull(emails.contains(contact.Email), 'The result should contain the expected email addresses.');
        }
    }

    @isTest
    static void testGetContactByEmail() {
        String email = 'john.doe@example.com';
        ContactDAO contactDAO = new ContactDAO();
        Contact result = contactDAO.getContactByEmail(email);

        Assert.isNotNull(result, 'The result should not be null.');
        Assert.areEqual(email, result.Email, 'The email of the fetched contact should match the requested email.');

        String invalidEmail = 'nonexistent@example.com';
        Contact nullResult = contactDAO.getContactByEmail(invalidEmail);

        Assert.isNull(nullResult, 'The result should be null for a nonexistent email.');
    }
}