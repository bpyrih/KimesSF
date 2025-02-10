@isTest
public with sharing class ProjectTaskTriggerServiceTest {
    @testSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Username = 'john.doe@exampleA123.com.test',
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;

        // // Create test Project_Tasks
        // List<Project_Task__c> tasks = new List<Project_Task__c>{
        //     new Project_Task__c(Name = 'Task 1', Assigned_To__c = testUser.Id),
        //     new Project_Task__c(Name = 'Task 2')
        // };
        // insert tasks;
    }

    @isTest
    static void testHandleAssignedToSharing() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Username = 'john.doe@exampleA123.com.test' LIMIT 1];
        List<Project_Task__c> newTasks = new List<Project_Task__c> {
            new Project_Task__c(Name = 'Task 3', Assigned_To__c = testUser.Id),
            new Project_Task__c(Name = 'Task 4', Assigned_To__c = testUser.Id)
        };
        insert newTasks;

        // Assert
        List<Project_Task__Share> shares = [
            SELECT ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM Project_Task__Share WHERE RowCause != 'Owner'
        ];
        System.assert(!shares.isEmpty(), 'Shares should have been created.');
        System.assertEquals(newTasks.size(), shares.size(), 'All tasks should have shares created.');
    }

    @isTest
    static void testShareRecordWithAssignedUser() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Username = 'john.doe@exampleA123.com.test' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 7', Assigned_To__c = testUser.Id);
        insert task;

        // Assert
        List<Project_Task__Share> shares = [
            SELECT ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM Project_Task__Share
            WHERE ParentId = :task.Id AND RowCause != 'Owner'
        ];
        System.assertEquals(1, shares.size(), 'One share should have been created.');
        System.assertEquals(testUser.Id, shares[0].UserOrGroupId, 'Share should be assigned to the correct user.');
    }

    @isTest
    static void testUnshareRecordWithAssignedUser() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Username = 'john.doe@exampleA123.com.test' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 8', Assigned_To__c = testUser.Id);
        insert task;

        task.Assigned_To__c = null;
        update task;

        // Assert
        List<Project_Task__Share> remainingShares = [
            SELECT ParentId, AccessLevel, RowCause FROM Project_Task__Share WHERE ParentId = :task.Id AND RowCause != 'Owner'
        ];
        System.debug(remainingShares);
        System.assert(remainingShares.isEmpty(), 'All shares should have been removed.');
    }
}