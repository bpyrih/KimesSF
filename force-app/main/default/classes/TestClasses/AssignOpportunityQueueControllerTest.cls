@IsTest
private class AssignOpportunityQueueControllerTest {

    @IsTest
    static void testGetQueues() {

        Queue__c testQueue = new Queue__c(Name='Intake');
        insert testQueue;

        List<Queue__c> queues = AssignOpportunityQueueController.getQueues();
        System.assertNotEquals(0, queues.size(), 'Queues should not be empty');

        Boolean found = false;
        for (Queue__c q : queues) {
            if (q.Id == testQueue.Id) {
                found = true;
                break;
            }
        }
        System.assert(found, 'Queues should contain Intake');
    }

    @IsTest
    static void testGetOpportunityQueue() {

        Account acc = new Account(Name='Test Account');
        insert acc;

        Queue__c testQueue = new Queue__c(Name='Intake');
        insert testQueue;

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            AccountId=acc.Id,
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Project_Name__c='Test Project',
            Queue__c=testQueue.Id
        );
        insert opp;

        Id queueId = AssignOpportunityQueueController.getOpportunityQueue(opp.Id);
        System.assertEquals(testQueue.Id, queueId, 'Opportunity should have correct queue assigned');
    }

    @IsTest
    static void testAssignQueueToOpportunity_Success() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Queue__c queue1 = new Queue__c(Name='Intake');
        insert queue1;

        Queue__c queue2 = new Queue__c(Name='Accountant');
        insert queue2;

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            AccountId=acc.Id,
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Project_Name__c='Test Project',
            Queue__c=queue1.Id
        );
        insert opp;

        Id assignedQueueId = AssignOpportunityQueueController.assignQueueToOpportunity(opp.Id, queue2.Id);
        System.assertEquals(queue2.Id, assignedQueueId, 'Queue should be reassigned');

        Opportunity updatedOpp = [SELECT Queue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(queue2.Id, updatedOpp.Queue__c, 'Queue on Opportunity should be updated');
    }

    @IsTest
    static void testAssignQueueToOpportunity_Exception() {
        Account acc = new Account(Name='Test Account');
        insert acc;

        Queue__c queue1 = new Queue__c(Name='Intake');
        insert queue1;

        Opportunity opp = new Opportunity(
            Name='Test Opportunity',
            AccountId=acc.Id,
            StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            Project_Name__c='Test Project',
            Queue__c=queue1.Id
        );
        insert opp;

        Boolean exceptionThrown = false;

        try {
            AssignOpportunityQueueController.assignQueueToOpportunity(opp.Id, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('exception'), 'Exception message should indicate null Queue Id');
        }

        System.assert(exceptionThrown, 'AuraHandledException should be thrown when queueId is null');
    }
}
