@isTest
private class CustomNotificationSenderTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        // Create test users
        User testUser1 = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Username = 'john.doe@example123.com.test',
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;

        User testUser2 = new User(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@example.com',
            Username = 'jane.smith@example123.com.test',
            Alias = 'jsmith',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser2;
        
    }

    @isTest
    static void testSendNotificationToUser() {
        Account testAcc = [SELECT Id FROM Account];
        User testUser = [SELECT Id FROM User LIMIT 1];
        String notificationTitle = 'Test Notification';
        String notificationBody = 'This is a test notification body.';

        Boolean isSent = CustomNotificationSender.sendCustomNotification(testAcc.Id, new Set<String>{testUser.Id}, notificationTitle, notificationBody);

        Assert.isTrue(isSent, 'Notification should be sent successfully.');
    }

    @isTest
    static void testSendNotificationToGroup() {
        Account testAcc = [SELECT Id FROM Account];
        List<User> users = [SELECT Id FROM User];
        Set<String> userIds = new Set<String>();
        for (User u : users) {
            userIds.add(u.Id);
        }

        String notificationTitle = 'Group Notification';
        String notificationBody = 'This is a test group notification body.';

        Boolean isSent = CustomNotificationSender.sendCustomNotification(testAcc.Id, userIds, notificationTitle, notificationBody);

        Assert.isTrue(isSent, 'Notification to the group should be sent successfully.');
    }
}