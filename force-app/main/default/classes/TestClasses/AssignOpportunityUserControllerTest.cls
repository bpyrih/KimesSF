@IsTest
private class AssignOpportunityUserControllerTest {

    @TestSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email='testuser@example.com',
            EmailEncodingKey='UTF-8',
            LastName='UserA',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='Europe/Kiev',
            ProfileId = p.Id,
            UserName='testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert u;

        Queue__c q = new Queue__c(Name='Intake');
        insert q;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Project_Name__c = 'Test Project',
            Queue__c = q.Id
        );
        insert opp;
    }

    @IsTest
    static void testGetAssignableUsers() {
        User testUser = [SELECT Id FROM User WHERE LastName='UserA' LIMIT 1];

        List<AssignOpportunityUserController.IdNameWrapper> result =
            AssignOpportunityUserController.getAssignableUsers();

        System.assertNotEquals(0, result.size(), 'Result should not be empty');

        Boolean found = false;
        for (AssignOpportunityUserController.IdNameWrapper r : result) {
            if (r.Id == testUser.Id) {
                found = true;
                break;
            }
        }
        System.assert(found, 'Result should contain testUser');
    }

    @IsTest
    static void testAssignOpportunityToUser_NullParams() {
        User testUser = [SELECT Id FROM User WHERE LastName='UserA' LIMIT 1];

        Boolean exceptionThrown = false;
        try {
            AssignOpportunityUserController.assignOpportunityToUser(null, testUser.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('exception'));
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for null opportunityId');

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Queue__c != null LIMIT 1];
        exceptionThrown = false;
        try {
            AssignOpportunityUserController.assignOpportunityToUser(opp.Id, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('exception'));
        }
        System.assert(exceptionThrown, 'AuraHandledException should be thrown for null userId');
    }

   @IsTest
static void testAssignOpportunityToUser_QueueEmpty() {
    User testUser = [SELECT Id FROM User WHERE LastName='UserA' LIMIT 1];

    Queue__c q = [SELECT Id FROM Queue__c WHERE Name='Intake' LIMIT 1];
    Opportunity oppEmptyQueue = new Opportunity(
        Name = 'Test Opp Empty Queue',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(10),
        Project_Name__c = 'Test Project',
        Queue__c = q.Id
    );
    insert oppEmptyQueue;

    oppEmptyQueue.Queue__c = null;
    update oppEmptyQueue;

    Boolean exceptionThrown = false;
    try {
        AssignOpportunityUserController.assignOpportunityToUser(oppEmptyQueue.Id, testUser.Id);
    } catch (AuraHandledException e) {
        exceptionThrown = true;
        System.assert(e.getMessage().contains('exception'));
    }
    System.assert(exceptionThrown, 'AuraHandledException should be thrown when Queue__c is empty');
}


    @IsTest
    static void testAssignOpportunityToUser_Success() {
        User testUser = [SELECT Id FROM User WHERE LastName='UserA' LIMIT 1];
        Opportunity opp = [SELECT Id, Queue__c FROM Opportunity WHERE Queue__c != null LIMIT 1];

        Test.startTest();
        AssignOpportunityUserController.assignOpportunityToUser(opp.Id, testUser.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Id, OwnerId, Queue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(testUser.Id, updatedOpp.OwnerId, 'Owner should be reassigned');
        System.assertEquals(null, updatedOpp.Queue__c, 'Queue__c should be cleared');
    }
}
